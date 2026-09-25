// L3b — Formats WOD (KT-008) : Tabata de bout en bout (définition, phases,
// chrono, saisie par intervalle, score, records), puis règles des autres
// formats, lecture des anciens résultats, import/export et garanties L2/L3.
// Horloge contrôlée (fakeAsync ou `storeClock`), données synthétiques,
// stockage simulé : aucune donnée réelle.

import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/persistence.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/timers.dart';
import 'package:streetlift_tracker/wod_formats.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_screen.dart';

import 'l2_fixtures.dart';

/// Les 40 Tabata du catalogue (générateur, famille 10), relevés sur la base
/// 2.5.5 par `tools/wod_catalog_snapshot.dart`.
const tabataIds = [
  for (final base in [100, 220, 340, 460])
    for (var k = 0; k < 10; k++) 'genx${base + k}',
];
const deathByIds = [
  'genx110', 'genx111', 'genx112', 'genx113', 'genx114', 'genx115', //
  'genx116', 'genx117', 'genx118', 'genx119', 'genx231', 'genx235',
  'genx236', 'genx237', 'genx351', 'genx352', 'genx355', 'genx357',
  'genx470', 'genx475', 'genx479',
];
const amrapBlockIds = [
  for (final base in [60, 180, 300, 420])
    for (var k = 0; k < 10; k++) 'genx${base + k}',
];

/// Empreinte FNV-1a 32 bits des définitions du catalogue 2.5.5 (sans
/// résultats, niveau ni format), une ligne JSON par WOD : 1 000 WODs,
/// 385 382 octets. Calculée sur l'instantané de la base.
const baseCatalogFnv = 0x755f39d8;

int fnv(List<int> bytes) {
  var h = 0x811C9DC5;
  for (final b in bytes) {
    h ^= b;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

WodResult legacy(
  String at, {
  int? seconds,
  int? rounds,
  int? reps,
  bool completed = true,
}) => WodResult(
  at: at,
  score: 'ancien',
  seconds: seconds,
  rounds: rounds,
  reps: reps,
  completed: completed,
);

WodResult tabataResult(
  Wod w,
  List<List<int?>> intervals, {
  bool completed = true,
  String at = '2026-09-10T10:00:00',
}) {
  final r = WodResult(
    at: at,
    score: '',
    intervals: intervals,
    completed: completed,
    scoring: ScoreRule.tabata.id,
  );
  r.reps = completed ? performance(ScoreRule.tabata, r)?.toInt() : null;
  r.score = scoreText(w, r);
  return r;
}

List<List<int?>> full(int blocks, List<int?> values) => [
  for (var b = 0; b < blocks; b++) List<int?>.of(values),
];

/// Ancienne règle de record (avant L3b), réécrite ici comme oracle.
int oldRecordXp(List<Wod> wods) {
  var xp = 0;
  for (final w in wods) {
    final results = [...w.results]..sort((a, b) => a.at.compareTo(b.at));
    WodResult? best;
    for (final r in results) {
      if (!legacyValid(w, r)) continue;
      if (best == null) {
        best = r;
        xp += 40;
      } else if (legacyBeats(w, r, best)) {
        best = r;
        xp += 40;
      }
    }
  }
  return xp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  group('Catalogue : définitions explicites, rien d’autre ne bouge', () {
    final catalog = AppStore().catalogWods();
    Wod byId(String id) => catalog.firstWhere((w) => w.id == id);

    test('définitions 2.5.5 identiques octet pour octet (hors format)', () {
      final lines = [
        for (final w in catalog)
          jsonEncode(
            w.toJson()
              ..remove('results')
              ..remove('level')
              ..remove('format'),
          ),
      ];
      final bytes = utf8.encode(lines.join('\n'));
      expect(catalog, hasLength(1000));
      expect(catalog.map((w) => w.id).toSet(), hasLength(1000));
      expect(bytes.length, 385382);
      expect(fnv(bytes), baseCatalogFnv);
    });

    test(
      'formats ajoutés : 40 Tabata, 40 AMRAP en blocs, 21 Death by, 1 E5MOM',
      () {
        final kinds = <String, List<String>>{};
        for (final w in catalog) {
          final f = w.format;
          if (f != null) (kinds[f.kind] ??= []).add(w.id);
        }
        expect(kinds['tabata'], tabataIds);
        expect(kinds['amrap-blocks'], amrapBlockIds);
        expect(kinds['death-by'], deathByIds);
        expect(kinds['emom-reps'], ['seed29']);
        expect(kinds.keys.toSet(), {
          'tabata',
          'amrap-blocks',
          'death-by',
          'emom-reps',
        });
        // Aucune routine n'est devenue Tabata par son titre.
        expect(
          catalog.where((w) => w.name.startsWith('Tabata')).map((w) => w.id),
          tabataIds,
        );
      },
    );

    test('Tabata : exercices, ordre, durées et lignes conservés', () {
      for (final id in tabataIds) {
        final w = byId(id);
        final f = w.format!;
        expect(w.type, 'routine');
        expect(f.validFor(w.type), isTrue);
        expect((f.sets, f.work, f.rest, f.blockRest), (8, 20, 10, 60));
        expect(f.movements.length, anyOf(3, 4));
        expect(w.lines, [
          for (final m in f.movements) '8 × (max $m en 20 s) · 10 s de repos',
        ]);
        expect(ruleFor(w), ScoreRule.tabata);
        expect(w.typeLabel, 'Tabata');
      }
      expect(byId('genx100').format!.movements, [
        'push-ups',
        'box jumps',
        'hollow rocks',
      ]);
    });

    test('règle de chaque famille', () {
      expect(ruleFor(byId('seed4')), ScoreRule.time); // For Time
      expect(ruleFor(byId('seed1')), ScoreRule.time); // rounds
      expect(ruleFor(byId('seed24')), ScoreRule.amrap);
      expect(ruleFor(byId('seed37')), ScoreRule.emomMinutes);
      expect(ruleFor(byId('seed58')), ScoreRule.emomMinutes);
      expect(ruleFor(byId('seed29')), ScoreRule.emomReps);
      expect(ruleFor(byId('genx110')), ScoreRule.deathBy);
      expect(ruleFor(byId('genx60')), ScoreRule.amrapBlocks);
      expect(ruleFor(byId('seed2')), ScoreRule.none); // routine sans règle
      expect(ruleFor(byId('seed12')), ScoreRule.none); // AMRAP 3-4-5
      for (final w in catalog) {
        expect(ruleText(w), isNotEmpty);
      }
    });

    test('format incohérent avec le type : ignoré (règle du type)', () {
      final w = Wod(
        id: 'x',
        name: 'x',
        type: 'emom',
        rounds: 10,
        format: const WodFormat.tabata(
          movements: ['a'],
          sets: 8,
          work: 20,
          rest: 10,
          blockRest: 60,
        ),
      );
      expect(ruleFor(w), ScoreRule.emomMinutes);
      expect(phasesOf(w), isNull);
    });
  });

  // =========================================================================
  group('Tabata : chronologie des phases', () {
    final catalog = AppStore().catalogWods();
    Wod byId(String id) => catalog.firstWhere((w) => w.id == id);

    test('3 mouvements : 47 phases, 810 s, fin au dernier effort', () {
      final phases = phasesOf(byId('genx100'))!;
      expect(phases, hasLength(3 * 15 + 2));
      expect(phasesDuration(phases), 3 * (8 * 20 + 7 * 10) + 2 * 60);
      expect(phasesDuration(phases), 810);
      // Bloc 1 : effort, repos… 8e effort puis repos entre mouvements.
      expect(phases.take(3).map((p) => (p.kind, p.seconds)), [
        (PhaseKind.work, 20),
        (PhaseKind.rest, 10),
        (PhaseKind.work, 20),
      ]);
      expect((phases[14].kind, phases[14].interval), (PhaseKind.work, 7));
      expect((phases[15].kind, phases[15].seconds), (PhaseKind.blockRest, 60));
      expect(
        (phases.last.kind, phases.last.block, phases.last.interval),
        (PhaseKind.work, 2, 7),
      );
      expect(byId('genx100').header(), contains('13 min 30 s'));
    });

    test('4 mouvements : 1 100 s', () {
      final phases = phasesOf(byId('genx105'))!;
      expect(phasesDuration(phases), 4 * 230 + 3 * 60);
    });

    test('AMRAP en blocs : 4-5-6 min, 2 min entre deux', () {
      final phases = phasesOf(byId('genx60'))!;
      expect(phases.map((p) => (p.kind, p.seconds)), [
        (PhaseKind.work, 240),
        (PhaseKind.blockRest, 120),
        (PhaseKind.work, 300),
        (PhaseKind.blockRest, 120),
        (PhaseKind.work, 360),
      ]);
    });
  });

  // =========================================================================
  group('WodClock par phases (horloge simulée)', () {
    setUp(() {
      store.settings.sound = store.settings.vibration = false;
    });
    final w = AppStore().catalogWods().firstWhere((w) => w.id == 'genx100');
    final phases = phasesOf(w)!;

    test('transitions juste avant, au moment exact et après', () {
      fakeAsync((async) {
        final c = WodClock(now: async.getClock(DateTime(2026)).now);
        c.startPhases(phases);
        expect(
          (c.phaseIndex, c.phase!.kind, c.phaseRemaining),
          (0, PhaseKind.work, 20),
        );
        async.elapse(const Duration(milliseconds: 19800));
        expect((c.phaseIndex, c.phaseRemaining), (0, 1));
        async.elapse(const Duration(milliseconds: 200)); // 20,000 s
        expect(
          (c.phaseIndex, c.phase!.kind, c.phaseRemaining),
          (1, PhaseKind.rest, 10),
        );
        async.elapse(const Duration(milliseconds: 9800)); // 29,8 s
        expect((c.phaseIndex, c.phaseRemaining), (1, 1));
        async.elapse(const Duration(milliseconds: 400)); // 30,2 s
        expect((c.phaseIndex, c.phase!.interval), (2, 1));
        expect(c.beeps, 2);
        c.dispose();
      });
    });

    test('pause et reprise pendant l’effort et le repos', () {
      fakeAsync((async) {
        final c = WodClock(now: async.getClock(DateTime(2026)).now);
        c.startPhases(phases);
        async.elapse(const Duration(seconds: 12));
        c.toggle(); // pause en effort
        async.elapse(const Duration(minutes: 5));
        expect((c.phaseIndex, c.phaseRemaining), (0, 8));
        c.toggle();
        async.elapse(const Duration(seconds: 10)); // 22 s actives : repos
        expect((c.phaseIndex, c.phaseRemaining), (1, 8));
        c.toggle(); // pause en repos
        async.elapse(const Duration(minutes: 3));
        expect((c.phaseIndex, c.phaseRemaining), (1, 8));
        c.toggle();
        async.elapse(const Duration(seconds: 8)); // 30 s actives
        expect((c.phaseIndex, c.phase!.kind), (2, PhaseKind.work));
        expect(c.elapsed, 30);
        c.dispose();
      });
    });

    test('rafraîchissement tardif : pas de phase prolongée, pas de rafale', () {
      var now = DateTime(2026);
      final c = WodClock(now: () => now);
      c.startPhases(phases);
      // Retour dans l'application 95 s plus tard, en un seul rafraîchissement.
      now = now.add(const Duration(seconds: 95));
      c.stop(); // force un calcul puis fige
      // 95 s = 3 intervalles de 30 s (90 s) + 5 s d'effort du 4e.
      expect(
        (c.phaseIndex, c.phase!.kind, c.phase!.interval),
        (6, PhaseKind.work, 3),
      );
      expect(c.phaseRemaining, 15);
      expect(c.beeps, 0); // transitions anciennes : aucune alerte rejouée
      c.dispose();
    });

    test('dernier effort : fin unique, sans dernier repos', () {
      fakeAsync((async) {
        final c = WodClock(now: async.getClock(DateTime(2026)).now);
        c.startPhases(phases);
        async.elapse(const Duration(seconds: 809));
        expect(c.finished, isFalse);
        expect(
          (c.phase!.kind, c.phase!.block, c.phase!.interval),
          (PhaseKind.work, 2, 7),
        );
        async.elapse(const Duration(seconds: 1));
        expect(c.finished, isTrue);
        expect(c.elapsed, 810);
        expect(c.alarms, 1);
        async.elapse(const Duration(seconds: 30));
        expect(c.alarms, 1);
        expect(c.beeps, 46); // une alerte par transition, aucune en double
        c.dispose();
      });
    });

    test('fin découverte tard : pas d’alarme ancienne', () {
      var now = DateTime(2026);
      final c = WodClock(now: () => now);
      c.startPhases(phases);
      now = now.add(const Duration(seconds: 900));
      c.stop();
      expect(c.finished, isTrue);
      expect((c.alarms, c.beeps), (0, 0));
      c.dispose();
    });

    test('préparation : hors durée du WOD', () {
      fakeAsync((async) {
        final c = WodClock(now: async.getClock(DateTime(2026)).now);
        c.startPhases(phases, prep: 5);
        expect(c.phase!.kind, PhaseKind.prep);
        async.elapse(const Duration(seconds: 5));
        expect((c.phase!.kind, c.phase!.interval), (PhaseKind.work, 0));
        async.elapse(const Duration(seconds: 810));
        expect(c.finished, isTrue);
        expect(c.workElapsed, 810);
        c.dispose();
      });
    });
  });

  // =========================================================================
  group('Tabata : score et comparaison', () {
    final w = AppStore().catalogWods().firstWhere((w) => w.id == 'genx100');

    test('minimum par mouvement, zéro compté, total des minimums', () {
      final r = tabataResult(w, [
        [12, 11, 10, 10, 9, 9, 8, 9],
        [15, 14, 0, 13, 12, 12, 11, 11],
        [20, 18, 17, 16, 16, 15, 15, 14],
      ]);
      expect(tabataMinima(r), [8, 0, 14]);
      expect(performance(ScoreRule.tabata, r, w.format), 22);
      expect(r.score, 'Total 22 reps · minimums 8 · 0 · 14');
      expect(isRanked(w..results = [r], r), isTrue);
    });

    test('champ manquant : partiel, jamais complété ni classé', () {
      final r = tabataResult(w, [
        [12, 11, 10, 10, 9, 9, 8, 9],
        [15, null, 13, 13, 12, 12, 11, 11],
        [null, null, null, null, null, null, null, null],
      ], completed: false);
      expect(tabataMinima(r), [8, null, null]);
      expect(performance(ScoreRule.tabata, r, w.format), isNull);
      expect(r.score, 'Partiel · minimums 8 · — · —');
      expect(r.reps, isNull);
      w.results = [r];
      expect(w.best(), isNull);
      // Même déclaré « complet », il manque des données : pas classé.
      final lying = tabataResult(w, r.intervals!, completed: true);
      w.results = [lying];
      expect(w.best(), isNull);
    });

    test(
      'deux nouveaux résultats : le total le plus haut, égalité = premier',
      () {
        final a = tabataResult(w, full(3, [10, 10, 10, 10, 10, 10, 10, 10]));
        final b = tabataResult(w, full(3, [11, 12, 11, 12, 11, 12, 11, 12]));
        final c = tabataResult(w, full(3, [11, 20, 20, 20, 20, 20, 20, 20]));
        w.results = [a, b, c];
        expect(performance(ScoreRule.tabata, b, w.format), 33);
        expect(identical(w.best(), b), isTrue); // c égale b : b reste
      },
    );

    test('ancien temps Tabata : conservé, jamais converti ni comparé', () {
      final old = legacy('2026-09-01T10:00:00', seconds: 600);
      final json = jsonEncode(old.toJson());
      w.results = [old];
      expect(w.best(), isNull);
      expect(readRule(w, old), isNull);
      expect(historicalNote(w, old), contains('Ancien score au temps'));
      expect(old.reps, isNull);
      final fresh = tabataResult(w, full(3, [5, 5, 5, 5, 5, 5, 5, 5]));
      w.results = [old, fresh];
      expect(identical(w.best(), fresh), isTrue);
      expect(jsonEncode(old.toJson()), json);
    });
  });

  // =========================================================================
  group('Autres formats : règle, validité, sens de comparaison', () {
    final catalog = AppStore().catalogWods();
    Wod byId(String id) =>
        Wod.fromJson(catalog.firstWhere((w) => w.id == id).toJson());
    WodResult v(
      ScoreRule rule, {
      int? seconds,
      int? rounds,
      int? reps,
      bool completed = true,
    }) => WodResult(
      at: '2026-09-10T10:00:00',
      score: '',
      seconds: seconds,
      rounds: rounds,
      reps: reps,
      completed: completed,
      scoring: rule.id,
    );

    test(
      'For Time : plus court gagne ; incomplet (arrêt rapide) exclu ; ancien comparable',
      () {
        final w = byId('seed4');
        final quickStop = v(ScoreRule.time, seconds: 30, completed: false);
        final old = legacy('2026-09-01T10:00:00', seconds: 2400);
        final fresh = v(ScoreRule.time, seconds: 2300);
        w.results = [old, quickStop, fresh];
        expect(identical(w.best(), fresh), isTrue);
        expect(readRule(w, old), ScoreRule.time);
        w.results = [old, quickStop];
        expect(identical(w.best(), old), isTrue);
        // Égalité : le premier reste.
        final same = v(ScoreRule.time, seconds: 2400);
        w.results = [old, same];
        expect(identical(w.best(), old), isTrue);
      },
    );

    test('AMRAP : rounds puis reps ; interrompu exclu', () {
      final w = byId('seed24');
      final a = v(ScoreRule.amrap, rounds: 8, reps: 5);
      final b = v(ScoreRule.amrap, rounds: 8, reps: 6);
      final stopped = v(ScoreRule.amrap, rounds: 20, reps: 0, completed: false);
      w.results = [a, b, stopped];
      expect(identical(w.best(), b), isTrue);
      expect(scoreText(w, b), '8 rounds + 6');
    });

    test('EMOM : minutes tenues ; ancien « rounds + reps » à part', () {
      final w = byId('seed37');
      final old = legacy('2026-09-01T10:00:00', rounds: 15, reps: 40);
      final a = v(ScoreRule.emomMinutes, rounds: 13);
      final b = v(ScoreRule.emomMinutes, rounds: 12);
      w.results = [old, a, b];
      expect(identical(w.best(), a), isTrue);
      expect(scoreText(w, a), '13/15 minutes tenues');
      expect(historicalNote(w, old), contains('rounds + reps'));
    });

    test('E5MOM : total de tractions', () {
      final w = byId('seed29');
      final a = v(ScoreRule.emomReps, reps: 60);
      final b = v(ScoreRule.emomReps, reps: 75);
      w.results = [a, b];
      expect(identical(w.best(), b), isTrue);
      expect(scoreText(w, b), '75 tractions');
    });

    test('Death by : dernière minute réussie', () {
      final w = byId('genx110');
      final a = v(ScoreRule.deathBy, rounds: 11);
      final b = v(ScoreRule.deathBy, rounds: 9);
      w.results = [a, b];
      expect(identical(w.best(), a), isTrue);
      expect(scoreText(w, a), 'Minute 11 réussie');
      expect(
        scoreText(w, v(ScoreRule.deathBy, rounds: 0)),
        'Aucune minute réussie',
      );
    });

    test('AMRAP en blocs : total des rounds', () {
      final w = byId('genx60');
      final a = v(ScoreRule.amrapBlocks, rounds: 14);
      final b = v(ScoreRule.amrapBlocks, rounds: 16);
      w.results = [a, b];
      expect(identical(w.best(), b), isTrue);
      expect(scoreText(w, b), '16 rounds au total');
    });

    test('routine sans règle : temps noté, jamais de record', () {
      final w = byId('seed2');
      final old = legacy('2026-09-01T10:00:00', seconds: 900);
      final a = v(ScoreRule.none, seconds: 800);
      w.results = [old, a];
      expect(w.best(), isNull);
      expect(scoreText(w, a), '13:20');
      expect(historicalNote(w, old), contains('sans record'));
    });

    test('valeur absente : aucune performance inventée', () {
      for (final rule in ScoreRule.values) {
        expect(performance(rule, v(rule)), isNull, reason: rule.id);
      }
    });
  });

  // =========================================================================
  group('Saisie : nombres', () {
    test('entiers seulement, zéro accepté, espaces tolérés', () {
      expect(parseCount('0'), 0);
      expect(parseCount(' 12 '), 12);
      for (final bad in [
        '',
        ' ',
        '-1',
        '2.5',
        '2,5',
        '1e3',
        '+3',
        'abc',
        '12 reps',
        'NaN',
        'Infinity',
      ]) {
        expect(parseCount(bad), isNull, reason: bad);
      }
      expect(parseCount('1000', max: 999), isNull);
      expect(parseCount('16', max: 15), isNull);
    });
  });

  // =========================================================================
  group('Store : sauvegarde, import, XP et garanties L2/L3', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
      app.settings.sound = app.settings.vibration = false;
      app.storeClock = () => DateTime(2026, 9, 24, 10);
    });
    tearDown(() async {
      app.debugWriteHook = null;
      await app.flush();
      app.dispose();
    });
    Wod wod(String id) => app.wods.firstWhere((w) => w.id == id);

    /// Anciens résultats synthétiques (sans version) sur chaque famille.
    void seedLegacy() {
      wod('genx100').results.addAll([
        legacy('2026-09-01T10:00:00', seconds: 700),
        legacy('2026-09-03T10:00:00', seconds: 650),
      ]);
      wod('seed2').results.addAll([
        legacy('2026-09-02T10:00:00', seconds: 900),
        legacy('2026-09-05T10:00:00', seconds: 850),
      ]);
      wod('seed37').results.addAll([
        legacy('2026-09-02T11:00:00', rounds: 14, reps: 0),
        legacy('2026-09-06T11:00:00', rounds: 15, reps: 3),
      ]);
      wod('genx110').results.add(legacy('2026-09-04T10:00:00', rounds: 9));
      wod('seed4').results.addAll([
        legacy('2026-09-04T12:00:00', seconds: 2400),
        legacy('2026-09-07T12:00:00', seconds: 2300),
        legacy('2026-09-08T12:00:00', seconds: 30, completed: false),
      ]);
      wod(
        'seed24',
      ).results.add(legacy('2026-09-08T09:00:00', rounds: 8, reps: 2));
      app.notifyListeners();
    }

    test(
      'XP de record des anciens résultats inchangée (oracle ancienne règle)',
      () async {
        seedLegacy();
        final xp = app.progression.recordXp;
        expect(xp, oldRecordXp(app.wods));
        // Tabata 2 + routine 2 + EMOM 2 + Death by 1 + For Time 2 + AMRAP 1.
        expect(xp, 40 * 10);
      },
    );

    test(
      'nouveau Tabata : sauvegardé, exporté, réimporté à l’identique',
      () async {
        final w = wod('genx100');
        app.unlockedWods[w.id] = 0;
        final r = tabataResult(w, full(3, [9, 9, 8, 9, 9, 9, 9, 10]));
        expect(await app.recordWodResult(w, r), ResultSave.saved);
        final data = backupOf(app);
        final saved =
            ((data['catalog'] as Map)['results'] as Map)['genx100'] as List;
        expect(saved.single['scoring'], 'tabata/1');
        expect(saved.single['intervals'], full(3, [9, 9, 8, 9, 9, 9, 9, 10]));
        expect(saved.single['reps'], 24);
        final file = app.exportForFile(appVersion: 'test');
        for (var i = 0; i < 2; i++) {
          expect(await app.importBackup(file), ImportStatus.success);
          expect(wod('genx100').results, hasLength(1));
          expect(
            jsonEncode(wod('genx100').results.single.toJson()),
            jsonEncode(r.toJson()),
          );
          expect(
            identical(wod('genx100').best(), wod('genx100').results.single),
            isTrue,
          );
        }
      },
    );

    test(
      'double validation et échec d’écriture : un résultat, une récompense',
      () async {
        final w = wod('genx100');
        app.unlockedWods[w.id] = 0;
        final attempt = app.startAttempt(w)!;
        app.debugWriteHook = (_) async => false;
        final r = tabataResult(w, full(3, [7, 7, 7, 7, 7, 7, 7, 7]));
        expect(
          await app.recordWodResult(w, r, attempt: attempt),
          ResultSave.unsaved,
        );
        final reward = app.consumeReward();
        app.debugWriteHook = null;
        final again = tabataResult(w, full(3, [7, 7, 7, 7, 7, 7, 7, 7]));
        expect(
          await app.recordWodResult(w, again, attempt: attempt),
          ResultSave.saved,
        );
        expect(w.results, hasLength(1));
        expect(reward, isNotNull);
        expect(app.consumeReward(), isNull);
      },
    );

    test('essai Tabata commencé à 23 h 59, validé à 00 h 01', () async {
      // Seuls les Tabata restent jamais tentés : l'essai du jour en est un.
      for (final w in app.wods) {
        if (app.isCatalog(w) && w.format?.kind != 'tabata') {
          w.results.add(legacy('2026-09-01T10:00:00', seconds: 60));
        }
      }
      app.notifyListeners();
      app.storeClock = () => DateTime(2026, 9, 24, 23, 59);
      final trial = app.trialWod!;
      expect(ruleFor(trial), ScoreRule.tabata);
      final attempt = app.startAttempt(trial)!;
      app.storeClock = () => DateTime(2026, 9, 25, 0, 1);
      expect(app.isTrial(trial), isFalse);
      expect(app.canFinish(trial, attempt), isTrue);
      final blocks = trial.format!.movements.length;
      final result = tabataResult(
        trial,
        full(blocks, [5, 5, 5, 5, 5, 5, 5, 5]),
        at: '2026-09-25T00:01:00',
      );
      expect(
        await app.recordWodResult(trial, result, attempt: attempt),
        ResultSave.saved,
      );
      expect(trial.results.single.scoring, 'tabata/1');
      expect(trial.results.single.reps, 5 * blocks);
      expect(app.unlocked(trial), isFalse);
    });

    test(
      'ancienne sauvegarde : import répété sans conversion ni récompense',
      () async {
        seedLegacy();
        final trial = app.trialWod?.id;
        final weekly = app.weeklyIds;
        await app.flush();
        final old = app.exportForFile(appVersion: 'test');
        final xp = app.progression.totalXp;
        final grants = Map.of(app.creditGrants);
        final credits = app.credits;
        final results = jsonEncode(backupOf(app)['catalog']['results']);
        for (var i = 0; i < 2; i++) {
          expect(await app.importBackup(old), ImportStatus.success);
          await app.flush();
          expect(app.progression.totalXp, xp);
          expect(app.creditGrants, grants);
          expect(app.credits, credits);
          expect(app.trialWod?.id, trial);
          expect(app.weeklyIds, weekly);
          expect(jsonEncode(backupOf(app)['catalog']['results']), results);
          expect(app.consumeReward(), isNull);
          expect(app.consumeLevelUp(), isNull);
        }
        // Anciens résultats intacts, lus sans être réécrits.
        expect(wod('genx100').results.every((r) => r.scoring == null), isTrue);
      },
    );

    test('consultation des règles et records : aucune modification', () async {
      seedLegacy();
      await app.flush();
      final revision = app.dataRevision;
      final xp = app.progression.totalXp;
      for (final w in app.wods) {
        w.best();
        ruleText(w);
        for (final r in w.results) {
          resultDetails(w, r);
        }
      }
      expect(app.dataRevision, revision);
      expect(app.progression.totalXp, xp);
      expect(app.hasUnsavedChanges, isFalse);
    });

    test(
      'import refusé : règle inconnue, intervalle hors bornes, format incohérent',
      () async {
        final base = backupOf(app);
        Map<String, dynamic> withResult(Map<String, dynamic> r) {
          final data = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
          (data['catalog']['results'] as Map)['genx100'] = [r];
          return data;
        }

        final good = {
          'at': '2026-09-10T10:00:00',
          'score': 'x',
          'completed': true,
          'scoring': 'tabata/1',
          'intervals': full(3, [1, 1, 1, 1, 1, 1, 1, 1]),
        };
        expect(
          await app.importBackup(jsonEncode(withResult(good))),
          ImportStatus.success,
        );
        for (final bad in [
          {...good, 'scoring': 'tabata/9'},
          {
            ...good,
            'intervals': full(3, [1, 1, 1, 1, 1, 1, 1, 1000]),
          },
          {
            ...good,
            'intervals': full(3, [1, 1, 1, 1, 1, 1, 1, -1]),
          },
          {...good, 'intervals': 'beaucoup'},
          {...good, 'scoring': 3},
        ]) {
          final before = app.exportAll();
          expect(
            await app.importBackup(jsonEncode(withResult(bad))),
            ImportStatus.invalid,
          );
          expect(app.exportAll(), before);
        }
        final user = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        (user['catalog']['user'] as List).add({
          'id': 'u1',
          'name': 'Perso',
          'type': 'emom',
          'rounds': 10,
          'interval': 60,
          'lines': ['x'],
          'format': {
            'kind': 'tabata',
            'movements': ['a'],
            'sets': 8,
            'work': 20,
            'rest': 10,
            'blockRest': 60,
          },
        });
        expect(await app.importBackup(jsonEncode(user)), ImportStatus.invalid);
      },
    );

    test(
      'suppression locale : nouveaux scores retirés, rien de restauré',
      () async {
        final w = wod('genx100');
        app.unlockedWods[w.id] = 0;
        await app.recordWodResult(
          w,
          tabataResult(w, full(3, [3, 3, 3, 3, 3, 3, 3, 3])),
        );
        expect((await app.eraseAllData()).status, EraseStatus.success);
        expect(wod('genx100').results, isEmpty);
        final next = AppStore();
        await next.init();
        expect(next.wods.firstWhere((x) => x.id == 'genx100').results, isEmpty);
        next.dispose();
      },
    );
  });

  // =========================================================================
  group('Écrans : runner Tabata et feuilles de score', () {
    var now = DateTime(2026, 9, 24, 10);
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..prepSec = 0;
    });
    setUp(() {
      now = DateTime(2026, 9, 24, 10);
      store.storeClock = () => now;
    });
    tearDown(() {
      store.storeClock = DateTime.now;
      store.debugWriteHook = null;
    });

    Widget page(Widget child, {double scale = 1}) => MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
      home: child,
    );

    void phone(WidgetTester tester, {double width = 320, double keyboard = 0}) {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
    }

    Future<void> advance(WidgetTester tester, Duration d) async {
      now = now.add(d);
      await tester.pump(const Duration(milliseconds: 250));
    }

    Wod owned(String id) {
      final w = store.wods.firstWhere((w) => w.id == id);
      store.unlockedWods[w.id] = 0;
      w.results.clear();
      store.notifyListeners();
      return w;
    }

    testWidgets(
      'Tabata de bout en bout à 320 px : phases, fin, saisie, record',
      (tester) async {
        phone(tester);
        final semantics = tester.ensureSemantics();
        final w = owned('genx100');
        await tester.pumpWidget(page(WodRunScreen(wodId: w.id)));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('wod-rule')), findsOneWidget);
        expect(find.text('Valider round'), findsNothing);
        await tester.tap(find.text('Démarrer'));
        await tester.pump();
        String title() =>
            tester.widget<Text>(find.byKey(const ValueKey('wod-phase'))).data!;
        String detail() =>
            tester
                .widget<Text>(find.byKey(const ValueKey('wod-phase-detail')))
                .data!;
        String digits() =>
            tester.widget<Text>(find.byKey(const ValueKey('wod-clock'))).data!;
        expect(title(), 'EFFORT');
        expect(detail(), 'Mouvement 1/3 · push-ups · intervalle 1/8');
        expect(digits(), '0:20');
        // La phase est annoncée comme région dynamique, pas les chiffres.
        expect(
          tester.getSemantics(find.byKey(const ValueKey('wod-phase'))),
          containsSemantics(label: 'EFFORT', isLiveRegion: true),
        );
        await advance(tester, const Duration(seconds: 20));
        expect(title(), 'REPOS');
        expect(detail(), contains('ensuite 2/8'));
        expect(digits(), '0:10');
        // Pause pendant le repos : rien n'avance.
        await tester.tap(find.text('Pause'));
        await advance(tester, const Duration(minutes: 2));
        expect((title(), digits()), ('REPOS', '0:10'));
        await tester.tap(find.text('Reprendre'));
        await advance(tester, const Duration(seconds: 220)); // fin du bloc 1
        expect(title(), 'REPOS ENTRE MOUVEMENTS');
        expect(detail(), 'Ensuite : mouvement 2/3 · box jumps');
        // 240 s → 800 s : dernier effort du dernier mouvement.
        await advance(tester, const Duration(seconds: 560));
        expect(
          (title(), detail()),
          ('EFFORT', 'Mouvement 3/3 · hollow rocks · intervalle 8/8'),
        );
        expect(digits(), '0:10');
        await advance(tester, const Duration(seconds: 10));
        await tester.pumpAndSettle();
        // Fin : la feuille s'ouvre d'elle-même, vide (aucune rep supposée).
        expect(find.byType(ScoreSheet), findsOneWidget);
        for (var b = 0; b < 3; b++) {
          for (var i = 0; i < 8; i++) {
            final cell = find.byKey(ValueKey('tabata-$b-$i'));
            expect(
              tester
                  .widget<EditableText>(
                    find.descendant(
                      of: cell,
                      matching: find.byType(EditableText),
                    ),
                  )
                  .controller
                  .text,
              '',
            );
            await tester.ensureVisible(cell);
            await tester.enterText(cell, '${b == 1 && i == 4 ? 0 : 10 + i}');
          }
        }
        await tester.pump();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('tabata-block-1')))
              .data,
          contains('plus faible : 0'),
        );
        // Correction avant confirmation : 0 devient 6.
        await tester.ensureVisible(find.byKey(const ValueKey('tabata-1-4')));
        await tester.enterText(find.byKey(const ValueKey('tabata-1-4')), '6');
        await tester.pump();
        final save = find.text('Enregistrer');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.tap(save, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(w.results, hasLength(1));
        final r = w.results.single;
        expect(r.scoring, 'tabata/1');
        expect(r.completed, isTrue);
        expect(tabataMinima(r), [10, 6, 10]);
        expect(r.reps, 26);
        expect(r.score, 'Total 26 reps · minimums 10 · 6 · 10');
        expect(r.seconds, 810);
        expect(identical(w.best(), r), isTrue);
        expect(tester.takeException(), isNull);
        store.consumeReward();
        store.consumeLevelUp();
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    Future<void> openSheet(
      WidgetTester tester,
      Wod w, {
      double scale = 1,
      double keyboard = 0,
    }) async {
      phone(tester, keyboard: keyboard);
      await tester.pumpWidget(
        page(
          Scaffold(
            body: Builder(
              builder:
                  (context) => Center(
                    child: FilledButton(
                      onPressed:
                          () => showModalBottomSheet<WodResult>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => ScoreSheet(wod: w, elapsed: 600),
                          ).then((r) async {
                            if (r != null) await store.recordWodResult(w, r);
                          }),
                      child: const Text('Score'),
                    ),
                  ),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.tap(find.text('Score'));
      await tester.pumpAndSettle();
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('Tabata partiel à ${(scale * 100).round()} %, clavier ouvert', (
        tester,
      ) async {
        final w = owned('genx105');
        await openSheet(tester, w, scale: scale, keyboard: 280);
        // Seul le premier mouvement est saisi.
        for (var i = 0; i < 8; i++) {
          final cell = find.byKey(ValueKey('tabata-0-$i'));
          await tester.ensureVisible(cell);
          await tester.enterText(cell, '4');
        }
        final done = find.text('Tabata terminé, tous les intervalles saisis');
        await tester.ensureVisible(done);
        await tester.tap(done);
        final save = find.text('Enregistrer');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Intervalles non renseignés : complète-les ou choisis « Incomplet ».',
          ),
          findsOneWidget,
        );
        expect(w.results, isEmpty);
        await tester.ensureVisible(find.text('Incomplet'));
        await tester.tap(find.text('Incomplet'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(w.results, hasLength(1));
        final r = w.results.single;
        expect(r.completed, isFalse);
        expect(tabataMinima(r), [4, null, null, null]);
        expect(r.score, 'Partiel · minimums 4 · — · — · —');
        expect(w.best(), isNull);
        expect(tester.takeException(), isNull);
        store.consumeReward();
        store.consumeLevelUp();
      });
    }

    testWidgets('Tabata : saisies invalides refusées', (tester) async {
      final w = owned('genx100');
      await openSheet(tester, w);
      for (final bad in ['-1', '2.5', 'abc', '1000']) {
        final cell = find.byKey(const ValueKey('tabata-0-0'));
        await tester.ensureVisible(cell);
        await tester.enterText(cell, bad);
        await tester.ensureVisible(find.text('Incomplet'));
        await tester.tap(find.text('Incomplet'));
        await tester.ensureVisible(find.text('Enregistrer'));
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(find.text('0-999'), findsOneWidget, reason: bad);
        expect(w.results, isEmpty);
      }
    });

    testWidgets('For Time : réalisation explicite et time cap respecté', (
      tester,
    ) async {
      final w = owned('seed39'); // time cap 12 min
      await openSheet(tester, w);
      final time = find.byType(TextFormField).first;
      await tester.enterText(time, '12:30');
      await tester.ensureVisible(find.text('Terminé en entier'));
      await tester.tap(find.text('Terminé en entier'));
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Au-delà du time cap (12 min) : choisis « Incomplet ».'),
        findsOneWidget,
      );
      await tester.ensureVisible(time);
      await tester.enterText(time, '11:40');
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(w.results.single.seconds, 700);
      expect(w.results.single.scoring, 'time/1');
      expect(identical(w.best(), w.results.single), isTrue);
      store.consumeReward();
      store.consumeLevelUp();
    });

    testWidgets('EMOM : aucune minute pré-remplie, borne à N', (tester) async {
      final w = owned('seed37');
      await openSheet(tester, w);
      final field = find.byType(TextFormField).first;
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: field, matching: find.byType(EditableText)),
            )
            .controller
            .text,
        '',
      );
      await tester.enterText(field, '16');
      await tester.ensureVisible(find.text('Terminé en entier'));
      await tester.tap(find.text('Terminé en entier'));
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre entier de 0 à 15'), findsOneWidget);
      await tester.ensureVisible(field);
      await tester.enterText(field, '0');
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(w.results.single.rounds, 0);
      expect(w.results.single.score, '0/15 minutes tenues');
      store.consumeReward();
      store.consumeLevelUp();
    });
  });
}
