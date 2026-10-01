// G2 (dev6.1.0, D1.1 et D1.2) : suppression des WOD, des séances manuelles,
// des crédits et de L12, après une copie complète vérifiée.
//
// Stockage simulé (SharedPreferences) : ces tests ne prouvent ni l'écriture
// native du fichier partagé, ni le menu de partage Android.

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/retired_data.dart';
import 'package:streetlift_tracker/retired_notice_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/retired_fixtures.dart';

const _key = 'kalis_state_v3';
const _at = '2026-07-01T10:00:00';

String _decode(String stored) => stored.startsWith('gz:')
    ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
    : stored;

Future<Map<String, dynamic>> _disk() async =>
    jsonDecode(
          _decode((await SharedPreferences.getInstance()).getString(_key)!),
        )
        as Map<String, dynamic>;

UserProfile _profile() {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.setField('birthYear', 1990, _at);
  p.setField('goalPrimary', 'strength', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  return p;
}

/// Document d'état de 6.0.x d'un utilisateur du programme : références,
/// départ, journées du programme (avec le champ `customId: null` que 6.0.x
/// écrivait), réglages, profil.
Future<Map<String, dynamic>> _programDocument() async {
  SharedPreferences.setMockInitialValues({});
  final seed = AppStore();
  await seed.init();
  final doc = jsonDecode(seed.exportAll()) as Map<String, dynamic>;
  final logs = <String, dynamic>{};
  var n = 0;
  for (final week in seed.program.weeks.take(3)) {
    for (final day in week.days.where((d) => d.exercises.isNotEmpty)) {
      final at = DateTime(2026, 7, 13 + n++, 18).toIso8601String();
      final log = SessionLog(done: true, finishedAt: at, title: 'S${week.n}');
      for (final ex in day.exercises) {
        log.exerciseNames[ex.id] = ex.name;
        log.ex[ex.id] = ExerciseLog(
          sets: [
            SetEntry(kg: '${40 + n}', reps: '5', done: true, completedAt: at),
          ],
          note: 'note $n',
        );
      }
      logs[seed.sessionKey(week.n, day.j)] = {
        ...log.toJson(),
        'customId': null,
      };
    }
  }
  seed.dispose();
  return doc
    ..['pilotage'] = {'B4': 78.0, 'B8': 22.5}
    ..['referenceStatus'] = {'B4': 'set', 'B8': 'set'}
    ..['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'user',
    }
    ..['logs'] = logs
    ..['settings'] =
        (AppSettings()
              ..theme = 'dark'
              ..accent = 'vert'
              ..defaultRest = 120)
            .toJson()
    ..['profile'] = _profile().toJson()
    ..['lastLevel'] = 3;
}

/// Journal sans le champ des séances manuelles (plus écrit depuis G2).
Map<String, dynamic> _withoutCustomId(Map<String, dynamic> logs) => {
  for (final e in logs.entries)
    e.key: Map<String, dynamic>.of(e.value as Map<String, dynamic>)
      ..remove('customId'),
};

Future<AppStore> _launch(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final app = AppStore();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppStore.debugRetiredCopyHook = null);

  group('Données retirées : repérage', () {
    test('sections, séances manuelles et compte de l’annonce', () {
      final doc = withRetiredData({'logs': <String, dynamic>{}});
      final retired = RetiredData.of(doc);
      expect(retired.sections.keys.toSet(), {
        'custom',
        'catalog',
        'unlocked',
        'legacyGrants',
        'creditsEarnedMax',
        'creditGrants',
        'trialOfDay',
        'weeklyShowcase',
        'wishlist',
        'motiv',
      });
      expect(retired.manualLogs.keys.toSet(), {'S0-J1', 'S0-J1@a1'});
      final s = retired.summary;
      expect(s.manualTemplates, 2);
      expect(s.manualSessionsDone, 2);
      expect(s.wodResults, 3);
      expect(s.wodsCustomized, 3);
      expect(s.wodsUnlocked, 3);
      expect(s.creditEntries, 4);
      expect(s.wishlist, 1);
      expect(s.motivation, isTrue);
      expect(s.hasUserData, isTrue);
      expect(s.lines, contains('3 résultats de WOD'));
      expect(RetiredSummary.fromJson(s.toJson()).toJson(), s.toJson());
    });

    test('catalogue vierge : aucune donnée de l’utilisateur', () {
      final doc = {...pristineRetiredSections(), 'logs': <String, dynamic>{}};
      final retired = RetiredData.of(doc);
      expect(retired.isEmpty, isFalse);
      expect(retired.summary.hasUserData, isFalse);
    });

    test('formats 1-2 : résultats comptés dans la liste des WOD', () {
      final retired = RetiredData.of({
        'wods': [
          {
            'id': 'seed1',
            'results': [
              {'at': '2026-01-01T00:00:00'},
            ],
          },
          {'id': 'seed2', 'results': <Object?>[]},
        ],
      });
      expect(retired.summary.wodResults, 1);
      expect(retired.summary.hasUserData, isTrue);
    });

    test('retrait et remise : le document revient à l’identique', () {
      final doc = withRetiredData({
        'kalisTrack': 1,
        'logs': {'S1-J1': manualSessionLog('x')},
      }, activeWod: false);
      final retired = RetiredData.of(doc);
      final stripped = RetiredData.strip(doc);
      expect(stripped.keys.any(kRetiredSections.contains), isFalse);
      expect((stripped['logs'] as Map).keys, ['S1-J1']);
      retired.restoreInto(stripped);
      expect(jsonDeepEquals(stripped, doc), isTrue);
    });
  });

  group('Premier lancement de dev6.1.0', () {
    test('copie complète vérifiée, puis seulement suppression', () async {
      final program = await _programDocument();
      final old = withRetiredData(program);
      final app = await _launch({_key: jsonEncode(old)});

      // Copie : texte exact du document de 6.0.x (chrono local retiré,
      // date de la copie ajoutée), importable comme une sauvegarde.
      final notice = app.retiredNotice!;
      expect(notice.seen, isFalse);
      expect(notice.summary.toJson(), RetiredData.of(old).summary.toJson());
      final copy = jsonDecode(app.retiredCopy!) as Map<String, dynamic>;
      expect(copy.remove('exportedAt'), isA<String>());
      final expected = Map<String, dynamic>.of(old)..remove('activeWod');
      expect(jsonDeepEquals(copy, expected), isTrue);
      expect(copy['format'], 3);
      expect(copy['catalog'], old['catalog']);
      expect(fnv1a32(app.retiredCopy!), notice.checksum);
      expect(utf8.encode(app.retiredCopy!).length, notice.bytes);
      expect(app.retiredCopyFailed, isFalse);

      // Document réécrit sans les données retirées.
      final disk = await _disk();
      expect(disk.keys.any(kRetiredSections.contains), isFalse);
      expect(disk.containsKey('activeWod'), isFalse);
      final logs = disk['logs'] as Map<String, dynamic>;
      expect(logs.keys.any(isManualSessionKey), isFalse);

      // Historique du programme, records, réglages, profil identiques.
      expect(
        jsonDeepEquals(
          logs,
          _withoutCustomId(program['logs'] as Map<String, dynamic>),
        ),
        isTrue,
      );
      final before = exerciseBests({
        for (final e in (program['logs'] as Map<String, dynamic>).entries)
          e.key: SessionLog.fromJson(e.value as Map<String, dynamic>),
      });
      final after = exerciseBests(app.logs);
      expect(after.keys.toSet(), before.keys.toSet());
      for (final k in before.keys) {
        expect(after[k]!.bestE1rm, before[k]!.bestE1rm, reason: k);
        expect(after[k]!.bestReps, before[k]!.bestReps, reason: k);
      }
      for (final k in [
        'pilotage',
        'referenceStatus',
        'programStart',
        'settings',
        'profile',
        'userExercises',
        'lastLevel',
      ]) {
        expect(jsonDeepEquals(disk[k], program[k]), isTrue, reason: k);
      }
      expect(app.settings.accent, 'vert');
      expect(app.profile?.intValue('sessionMinutes'), 45);

      // La copie se réimporte (aperçu : données retirées signalées).
      final preview = app.previewImport(app.retiredCopy!).preview!;
      expect(preview.ignored.hasUserData, isTrue);
      expect(preview.ignored.wodResults, 3);
      app.dispose();
    });

    test('relance : aucune nouvelle copie, rien à supprimer', () async {
      final old = withRetiredData(await _programDocument());
      final first = await _launch({_key: jsonEncode(old)});
      final notice = first.retiredNotice!;
      await first.markRetiredNoticeSeen();
      first.dispose();
      final next = AppStore();
      await next.init();
      expect(next.retiredNotice!.at, notice.at);
      expect(next.retiredNotice!.seen, isTrue);
      expect(next.retiredCopy, isNotNull);
      final disk = await _disk();
      expect(disk.keys.any(kRetiredSections.contains), isFalse);
      next.dispose();
    });

    test('échec de la copie : rien supprimé, nouvel essai au lancement '
        'suivant', () async {
      final old = withRetiredData(await _programDocument());
      AppStore.debugRetiredCopyHook = (_) async => false;
      final app = await _launch({_key: jsonEncode(old)});
      expect(app.retiredCopyFailed, isTrue);
      expect(app.retiredNotice, isNull);
      // Écrans retirés masqués, mais une écriture ordinaire garde tout.
      app.settings.theme = 'light';
      app.saveSettings();
      await app.flush();
      final kept = await _disk();
      for (final k in kRetiredSections) {
        if (old.containsKey(k)) {
          expect(jsonDeepEquals(kept[k], old[k]), isTrue, reason: k);
        }
      }
      final keptLogs = kept['logs'] as Map<String, dynamic>;
      expect(keptLogs['S0-J1'], isNotNull);
      expect(keptLogs['S0-J1@a1'], isNotNull);
      app.dispose();

      AppStore.debugRetiredCopyHook = null;
      final next = AppStore();
      await next.init();
      expect(next.retiredCopyFailed, isFalse);
      expect(next.retiredNotice!.summary.wodResults, 3);
      final copy = jsonDecode(next.retiredCopy!) as Map<String, dynamic>;
      expect(copy['catalog'], old['catalog']);
      expect((copy['settings'] as Map)['theme'], 'light');
      final disk = await _disk();
      expect(disk.keys.any(kRetiredSections.contains), isFalse);
      next.dispose();
    });

    test('catalogue jamais utilisé : ni copie ni annonce', () async {
      final doc = {...await _programDocument(), ...pristineRetiredSections()};
      final app = await _launch({_key: jsonEncode(doc)});
      expect(app.retiredNotice, isNull);
      expect(app.retiredCopy, isNull);
      final disk = await _disk();
      expect(disk.keys.any(kRetiredSections.contains), isFalse);
      app.dispose();
    });

    test('installation neuve : rien à copier', () async {
      final app = await _launch({});
      expect(app.retiredNotice, isNull);
      expect(app.retiredCopyFailed, isFalse);
      app.dispose();
    });

    test('ancienne sauvegarde 5.10.1 avec WOD : importée, WOD ignorés, '
        'message clair', () async {
      final program = await _programDocument();
      final old = withRetiredData(program, activeWod: false)
        ..['appVersion'] = '5.10.1'
        ..['exportedAt'] = '2026-09-30T08:00:00.000';
      final app = await _launch({});
      final preview = app.previewImport(jsonEncode(old)).preview!;
      expect(preview.ignored.hasUserData, isTrue);
      expect(preview.ignored.lines, isNotEmpty);
      expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
      expect(app.logs.keys.any(isManualSessionKey), isFalse);
      expect(app.logs.length, (program['logs'] as Map).length);
      final export = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(export.keys.any(kRetiredSections.contains), isFalse);
      // L'import ne crée pas de copie G2 : le fichier importé en est une.
      expect(app.retiredNotice, isNull);
      app.dispose();
    });
  });

  group('XP', () {
    test('les WOD et séances manuelles ne rapportent plus d’XP', () async {
      final program = await _programDocument();
      final app = await _launch({_key: jsonEncode(withRetiredData(program))});
      final done = (program['logs'] as Map).length;
      expect(app.progression.programXp, 100 * done);
      expect(app.progression.sessions, done);
      app.dispose();
    });
  });

  group('Écran d’annonce', () {
    Future<void> pump(WidgetTester tester, Widget child, bool dark) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: child,
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final dark in [true, false]) {
      testWidgets(
        'contenu, partage, « Compris » (${dark ? 'sombre' : 'clair'})',
        (tester) async {
          final old = withRetiredData(await _programDocument());
          await tester.runAsync(() async {
            SharedPreferences.setMockInitialValues({_key: jsonEncode(old)});
            store = AppStore();
            await store.init();
          });
          final shared = <String, String>{};
          RetiredCopyShare.debugHook = (name, text) async {
            shared[name] = text;
            return 'shared';
          };
          addTearDown(() => RetiredCopyShare.debugHook = null);
          await pump(tester, const RetiredNoticeScreen(), dark);
          expect(find.text('WOD et séances perso retirés'), findsOneWidget);
          expect(find.text('3 résultats de WOD'), findsOneWidget);
          expect(find.text('Copie complète vérifiée'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('retired-notice-share')));
          await tester.pumpAndSettle();
          expect(shared.length, 1);
          expect(shared.keys.single, startsWith('kalis-track-copie-avant-g2-'));
          expect(shared.values.single, store.retiredCopy);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('retired-notice-close')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const ValueKey('retired-notice-close')));
          await tester.pumpAndSettle();
          expect(store.retiredNotice!.seen, isTrue);
        },
      );
    }

    testWidgets('Réglages › Sauvegardes : la copie reste accessible', (
      tester,
    ) async {
      final old = withRetiredData(await _programDocument());
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({_key: jsonEncode(old)});
        store = AppStore();
        await store.init();
      });
      await pump(tester, const SettingsScreen(), true);
      final tile = find.byKey(const ValueKey('settings-retired-copy'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text('Copie de sécurité'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });
  });

  test('version affichée : « 6.1.0 » hors build de développement', () {
    expect(kVersion, '6.1.0');
    expect(kAppVersion, '6.1.0');
  });
}
