// L10 — instance de programme branchée sur le store (KT-050, KT-057) :
// migration du propriétaire (programme de 40 semaines identique, export
// inchangé), génération au départ d'un nouvel utilisateur, persistance et
// export, régénération de la suite (historique intact), annulation pendant
// 7 jours, mode Guidé, cycle suivant, import strict. Stockage simulé,
// horloge injectée, données synthétiques.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/program_generator.dart';
import 'package:streetlift_tracker/program_instance.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/l10_support.dart';

const _at = '2026-10-01T10:00:00';

UserProfile _profile({
  String origin = 'onboarding',
  String autonomy = 'assisted',
  Map<String, List<String>> places = const {
    'park': ['pullup_bar', 'dip_bars'],
  },
}) {
  final p = UserProfile(origin: origin, createdAt: _at);
  p.health
    ..consent = 'given'
    ..consentAt = _at
    ..answeredAt = _at;
  p.health.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  p.setField('birthYear', 1990, _at);
  p.setField('goalPrimary', 'strength', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', places, _at);
  p.setField('benchmarks', {'pushups': 3, 'pullups': 2}, _at);
  p.setField('autonomy', autonomy, _at);
  p.setField('tone', 'neutral', _at);
  return p;
}

Map<String, dynamic> _asset() => readGz('assets/programme_v33.json.gz');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 5, 9);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 5, 9);
      app = AppStore()..storeClock = () => clock;
      await app.init();
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

    test('migration du propriétaire : instance implicite, 40 semaines '
        'identiques au programme actuel, historique et export inchangés', () async {
      final filled = filledBackup(app);
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      final before = app.exportAll();
      final next = await relaunch();
      expect(next.programInstance, isNull);
      expect(next.programGenerated, isFalse);
      expect(next.programModel, 'expert_streetlifting');
      final asset = _asset();
      final weeks = asset['weeks'] as List;
      expect(next.program.weeks, hasLength(40));
      for (var w = 0; w < 40; w++) {
        final aw = weeks[w] as Map;
        final pw = next.program.weeks[w];
        expect(pw.n, aw['n']);
        expect(pw.block, aw['block']);
        for (var d = 0; d < 7; d++) {
          final ad = (aw['days'] as List)[d] as Map;
          final pd = pw.days[d];
          expect(pd.title, ad['title']);
          expect(
            [for (final e in pd.exercises) '${e.id}|${e.name}|${e.sets.value}|${e.intensity}'],
            [
              for (final e in ad['exercises'] as List)
                '${(e as Map)['id']}|${e['name']}|${(e['sets'] as Map)['value']}|${e['intensity']}',
            ],
          );
        }
      }
      expect(next.program.start, app.program.start);
      expect(next.exportAll(), before);
      expect(backupOf(next).containsKey('programInstance'), isFalse);
      expect(next.koachProgram.available, isTrue);
    });

    test('nouvel utilisateur : programme personnalisé généré au choix du '
        'départ, persisté, relu à l\'identique et exporté', () async {
      app.saveProfile(_profile());
      expect(
        await app.configureStart(DateTime(2026, 10, 5)),
        StartSave.saved,
      );
      expect(app.programGenerated, isTrue);
      final inst = app.programInstance!;
      expect(inst.weeks.length, inInclusiveRange(4, 6));
      expect(app.program.weeks, hasLength(inst.weeks.length));
      expect(app.program.start, DateTime(2026, 10, 5));
      expect(inst.undo, isNull);
      final json = jsonEncode(inst.toJson());
      final next = await relaunch();
      expect(jsonEncode(next.programInstance!.toJson()), json);
      expect(next.program.weeks.length, inst.weeks.length);
      expect(
        next.program.week(1).days.first.exercises.map((e) => e.name).toList(),
        app.program.week(1).days.first.exercises.map((e) => e.name).toList(),
      );
      expect(backupOf(next)['programInstance'], isA<Map>());
      // Rejouable : mêmes entrées et même graine → mêmes semaines.
      final data = L10Data.load();
      final replay = data.generate(
        GenInputs.fromJson(inst.inputs),
        seed: inst.seed,
      );
      expect(jsonEncode(replay.program['weeks']), jsonEncode(inst.weeks));
    });

    test('régénération à partir d\'aujourd\'hui : passé et journées saisies '
        'intacts, aperçu « ce qui change », annulation 7 jours', () async {
      app.saveProfile(_profile());
      await app.configureStart(DateTime(2026, 10, 5));
      final first = app.programInstance!;
      // S1·J1 faite.
      final day = app.program.week(1).day(1)!;
      final ex = day.exercises.last;
      final log = app.exLog(1, 1, ex);
      log.sets.first
        ..reps = '8'
        ..done = true
        ..completedAt = clock.toIso8601String();
      app.markSessionDone(1, 1, true);
      // Mercredi de la semaine 2 : passage à la salle.
      clock = DateTime(2026, 10, 14, 9);
      final p = app.profile!.copy();
      p.setField('places', {
        'gym': ['pullup_bar', 'dip_bars', 'dumbbells', 'barbell', 'rack', 'bench'],
      }, profileAt(clock));
      app.saveProfile(p);
      expect(app.programProfileChanged, isTrue);
      final prop = await app.proposeProgram(reason: 'profile');
      expect(prop, isNotNull);
      expect(prop!.from, (week: 2, day: 3));
      expect(prop.diff.weeks.first.lines, isNotEmpty);
      final oldW1 = jsonEncode(first.weeks.first);
      final oldW2J1 = jsonEncode((first.weeks[1]['days'] as List)[0]);
      app.applyProgram(prop);
      final inst = app.programInstance!;
      expect(jsonEncode(inst.weeks.first), oldW1);
      expect(jsonEncode((inst.weeks[1]['days'] as List)[0]), oldW2J1);
      expect(app.logs['S1-J1']!.done, isTrue);
      expect(app.programProfileChanged, isFalse);
      expect(app.programCanUndo, isTrue);
      // Annulation : version précédente rétablie.
      expect(app.undoProgram(), isTrue);
      expect(
        jsonEncode(app.programInstance!.weeks),
        jsonEncode(first.weeks),
      );
      expect(app.programCanUndo, isFalse);
    });

    test('annulation refusée après une séance du nouveau programme ; '
        'expirée après 7 jours', () async {
      app.saveProfile(_profile());
      await app.configureStart(DateTime(2026, 10, 5));
      clock = DateTime(2026, 10, 7, 9);
      final prop = await app.proposeProgram(
        options: const {'split': 'fullbody', 'focus': ''},
      );
      app.applyProgram(prop!);
      expect(app.programCanUndo, isTrue);
      final ex = app.program.week(1).day(3)!.exercises.last;
      app.exLog(1, 3, ex).sets.first
        ..reps = '5'
        ..done = true;
      app.markSessionDone(1, 3, true);
      expect(app.programCanUndo, isFalse);
      expect(app.undoProgram(), isFalse);
      final prop2 = await app.proposeProgram(
        options: const {'split': 'auto', 'focus': ''},
      );
      app.applyProgram(prop2!);
      clock = DateTime(2026, 10, 15, 9);
      expect(app.programCanUndo, isFalse);
    });

    test('mode Guidé : suite régénérée dès la modification du profil, '
        'annulable', () async {
      app.saveProfile(_profile(autonomy: 'guided'));
      await app.configureStart(DateTime(2026, 10, 5));
      final before = jsonEncode(app.programInstance!.weeks);
      clock = DateTime(2026, 10, 6, 9);
      final p = app.profile!.copy();
      p.setField('sessionMinutes', 30, profileAt(clock));
      app.saveProfile(p);
      await app.onProfileSavedForProgram();
      for (var k = 0; k < 20 && app.programProfileChanged; k++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(app.programProfileChanged, isFalse);
      expect(jsonEncode(app.programInstance!.weeks), isNot(before));
      expect(app.programCanUndo, isTrue);
    });

    test('cycle suivant généré pendant la dernière semaine, depuis le '
        'journal (calibrage), jamais au milieu du cycle', () async {
      app.saveProfile(_profile());
      await app.configureStart(DateTime(2026, 10, 5));
      final inst = app.programInstance!;
      final n = inst.weeks.length;
      expect(await app.extendProgramIfNeeded(), isFalse);
      // Calibrage des pompes saisi en semaine 1.
      for (final w in inst.weeks.take(1)) {
        for (final d in w['days'] as List) {
          for (final e in (d as Map)['exercises'] as List) {
            final em = e as Map;
            if (em['role'] != 'calibration') continue;
            final plan = app.program.week(1).day(d['j'] as int)!;
            final ex = plan.exercises.firstWhere((x) => x.id == em['id']);
            app.exLog(1, d['j'] as int, ex).sets.first
              ..reps = '20'
              ..effort = 2
              ..done = true;
          }
        }
      }
      clock = DateTime(2026, 10, 5 + (n - 1) * 7, 9);
      expect(await app.extendProgramIfNeeded(), isTrue);
      final next = app.programInstance!;
      expect(next.weeks.length, greaterThan(n));
      expect(next.cycle, 1);
      expect(jsonEncode(next.weeks.take(n).toList()), jsonEncode(inst.weeks));
      expect(next.history.last['reason'], 'cycle');
      expect(app.program.weeks.length, next.weeks.length);
    });

    test('export et import : instance relue à l\'identique ; section '
        'invalide refusée à l\'import, ignorée au démarrage', () async {
      app.saveProfile(_profile());
      await app.configureStart(DateTime(2026, 10, 5));
      final exported = app.exportAll();
      final other = await relaunch();
      SharedPreferences.setMockInitialValues({});
      final fresh = AppStore()..storeClock = () => clock;
      await fresh.init();
      others.add(fresh);
      expect(await fresh.importAll(exported), isTrue);
      expect(
        jsonEncode(fresh.programInstance!.toJson()),
        jsonEncode(other.programInstance!.toJson()),
      );
      expect(fresh.program.weeks.length, other.program.weeks.length);
      final broken = jsonDecode(exported) as Map<String, dynamic>;
      (broken['programInstance'] as Map)['weeks'] = [
        {'n': 3, 'days': []},
      ];
      expect(await fresh.importAll(jsonEncode(broken)), isFalse);
      expect(
        () => ProgramInstance.fromJson(broken['programInstance'], strict: true),
        throwsFormatException,
      );
      final issues = <String>[];
      expect(
        ProgramInstance.fromJson(broken['programInstance'], issues: issues),
        isNull,
      );
      expect(issues, isNotEmpty);
    });
  });

  test('le fichier de modèles est lisible et versionné', () {
    final raw =
        jsonDecode(File('assets/program_models.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(raw['version'], '1.0.0');
    expect(
      (raw['models'] as Map).keys,
      containsAll(['linear', 'undulating', 'block', 'health', 'expert_streetlifting']),
    );
  });
}
