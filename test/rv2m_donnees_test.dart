// RV2 (dev7.6.0, zone m : magasin, sauvegarde, import / export) — constats
// mineurs de RV1 corrigés, données jamais perdues :
//
// - M5 : « Où j'en suis » (`programResume`) illisible au démarrage gardé
//   tel quel et réécrit à l'identique (avant : perdu à la première
//   écriture) ; remplacé seulement par un nouveau choix ;
// - M6 : échecs d'écriture répétés : compteur à chaque échec, bannière
//   fixe tant que l'échec dure (avant : un seul message éphémère) ;
// - M7 : export (fichier, copie compacte) avec les données retirées dont
//   la copie de sécurité a échoué (avant : absentes du fichier) ;
// - M9 : copie locale de la sauvegarde d'origine refusée : réalignée dès
//   que le stockage accepte (avant : périmée pour toujours, puis reprise
//   comme origine) ;
// - aller-retour export → import → export à l'identique, et relance sur
//   le document écrit (format de dev7.5.1), sur un magasin synthétique
//   riche (programme PR2, séances, profil, Koach 1.0 actif).
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé (SharedPreferences, échecs injectés).
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/persistence_alert.dart';
import 'package:streetlift_tracker/retired_data.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'l2_fixtures.dart';
import 'support/retired_fixtures.dart';

const _stateKey = 'kalis_state_v3';
const _originKey = 'program_origin_v1';

String _unpack(String stored) => stored.startsWith('gz:')
    ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
    : stored;

Future<Map<String, dynamic>?> _stored(String key) async {
  final raw = (await SharedPreferences.getInstance()).getString(key);
  return raw == null ? null : jsonDecode(_unpack(raw)) as Map<String, dynamic>;
}

/// Sections de premier niveau qui diffèrent (diagnostic des échecs).
List<String> _diff(Map<String, dynamic> a, Map<String, dynamic> b) => [
  for (final k in {...a.keys, ...b.keys})
    if (!jsonDeepEquals(a[k], b[k])) k,
];

/// « Où j'en suis » d'une version plus récente (illisible ici).
const _futureResume = <String, Object?>{
  'v': 99,
  'at': '2026-10-01T08:00:00.000',
  'week': 3,
  'day': 2,
  'keys': ['S1-J1', 'S2-J1'],
  'nouveauChamp': {'a': 1},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clock = DateTime(2026, 10, 21, 9);

  Future<AppStore> launch([Map<String, Object>? prefs]) async {
    if (prefs != null) SharedPreferences.setMockInitialValues(prefs);
    final app = AppStore()..storeClock = () => clock;
    await app.init();
    return app;
  }

  /// Document d'état d'un utilisateur (journal rempli, départ posé).
  Future<Map<String, dynamic>> userDocument() async {
    final seed = await launch({});
    final doc = filledBackup(seed)
      ..['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'user',
      };
    seed.dispose();
    return doc;
  }

  tearDown(() {
    AppStore.debugRetiredCopyHook = null;
  });

  group('M5 « Où j’en suis » illisible', () {
    test('gardé tel quel au démarrage, réécrit à l’identique, jamais lu '
        'par les moteurs', () async {
      final doc = await userDocument();
      doc['programResume'] = _futureResume;
      // Journées de la reprise sans journal (les moteurs les liraient).
      (doc['logs'] as Map<String, dynamic>)
        ..remove('S1-J1')
        ..remove('S2-J1');
      final app = await launch({_stateKey: jsonEncode(doc)});
      expect(app.programResume, isNull);
      final export = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(jsonDeepEquals(export['programResume'], _futureResume), isTrue);
      // Une écriture ordinaire le garde (avant : section omise, perdue).
      app.settings.theme = 'light';
      app.saveSettings();
      await app.flush();
      final disk = (await _stored(_stateKey))!;
      expect(jsonDeepEquals(disk['programResume'], _futureResume), isTrue);
      expect((disk['settings'] as Map)['theme'], 'light');
      // Les moteurs ne lisent pas une reprise illisible.
      final sessions = app.coreTrainingLog().log.sessions;
      expect(sessions, isNotEmpty);
      expect(sessions.any((s) => s.id.startsWith('resume-')), isFalse);
      // Relance : toujours là.
      app.dispose();
      final next = await launch();
      expect(next.programResume, isNull);
      expect(
        jsonDeepEquals(
          (jsonDecode(next.exportAll()) as Map)['programResume'],
          _futureResume,
        ),
        isTrue,
      );
      next.dispose();
    });

    test('import strict : refusé, rien remplacé', () async {
      final app = await launch({});
      final b = await userDocument();
      b['programResume'] = _futureResume;
      final before = app.exportAll();
      expect(await app.importBackup(jsonEncode(b)), ImportStatus.invalid);
      expect(app.exportAll(), before);
      app.dispose();
    });

    test('un nouveau « Où j’en suis » le remplace (choix explicite)', () async {
      final doc = await userDocument();
      doc['programResume'] = _futureResume;
      final app = await launch({_stateKey: jsonEncode(doc)});
      app.setProgramPosition(4, 1);
      await app.flush();
      final resume = (await _stored(_stateKey))!['programResume'] as Map;
      expect(resume['v'], 1);
      expect(resume['week'], 4);
      expect(resume.containsKey('nouveauChamp'), isFalse);
      app.dispose();
    });
  });

  group('M6 échecs d’écriture répétés', () {
    test('chaque échec compte ; une écriture acceptée remet à zéro', () async {
      final app = await launch({});
      app.debugWriteHook = (_) async => false;
      app.settings.defaultRest = 100;
      app.saveSettings();
      await app.flush();
      final message = app.persistenceError.value;
      expect(message, isNotNull);
      expect(app.persistenceFailures.value, 1);
      // Deuxième échec : même message (ValueNotifier muet), compteur à 2.
      app.settings.defaultRest = 110;
      app.saveSettings();
      await app.flush();
      expect(app.persistenceError.value, message);
      expect(app.persistenceFailures.value, 2);
      app.debugWriteHook = null;
      expect(await app.retrySave(), isTrue);
      expect(app.persistenceError.value, isNull);
      expect(app.persistenceFailures.value, 0);
      app.dispose();
    });

    test('texte : le nombre d’échecs d’affilée à partir du deuxième', () {
      expect(
        persistenceAlertText('Sauvegarde impossible.', 1),
        'Sauvegarde impossible.',
      );
      expect(
        persistenceAlertText('Sauvegarde impossible.', 3),
        contains('3 essais refusés d’affilée'),
      );
    });

    group('bannière', () {
      late AppStore app;
      setUpAll(() async {
        app = await launch({});
      });
      tearDownAll(() => app.dispose());

      testWidgets('fixe tant que l’échec dure, mise à jour sur place, '
          'retirée à la première écriture acceptée', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PersistenceAlert(
              store: app,
              child: const Scaffold(body: SizedBox.expand()),
            ),
          ),
        );
        expect(find.byKey(const ValueKey('persistence-banner')), findsNothing);

        app.debugWriteHook = (_) async => false;
        await tester.runAsync(() => app.flush());
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('persistence-banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Sauvegarde impossible'), findsOneWidget);

        // Échec suivant, même message : la bannière reste (une seule) et
        // dit que rien ne s'enregistre toujours.
        await tester.runAsync(() => app.flush());
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('persistence-banner')),
          findsOneWidget,
        );
        expect(
          find.textContaining('2 essais refusés d’affilée'),
          findsOneWidget,
        );
        // Toujours là après le délai de l'ancien message (8 s).
        await tester.pump(const Duration(seconds: 30));
        expect(
          find.byKey(const ValueKey('persistence-banner')),
          findsOneWidget,
        );

        // « Réessayer » (même appel que le bouton) : le stockage accepte,
        // la bannière part.
        expect(find.byKey(const ValueKey('persistence-retry')), findsOneWidget);
        app.debugWriteHook = null;
        await tester.runAsync(() => app.retrySave());
        await tester.pumpAndSettle();
        expect(app.persistenceError.value, isNull);
        expect(find.byKey(const ValueKey('persistence-banner')), findsNothing);
        expect(find.text('Modifications enregistrées.'), findsOneWidget);
        // Message de confirmation parti (aucun minuteur laissé en cours).
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
      });
    });
  });

  group('M7 export et données retirées pas encore copiées', () {
    test('copie de sécurité refusée : le fichier et la copie compacte les '
        'contiennent ; l’aperçu de l’import les annonce', () async {
      final old = withRetiredData(await userDocument(), activeWod: false);
      AppStore.debugRetiredCopyHook = (_) async => false;
      final app = await launch({_stateKey: jsonEncode(old)});
      expect(app.retiredCopyFailed, isTrue);

      final file =
          jsonDecode(app.exportForFile(appVersion: 'rv2', at: clock))
              as Map<String, dynamic>;
      final compact =
          jsonDecode(_unpack(app.exportCompact())) as Map<String, dynamic>;
      for (final doc in [file, compact]) {
        for (final k in kRetiredSections) {
          if (old.containsKey(k)) {
            expect(jsonDeepEquals(doc[k], old[k]), isTrue, reason: k);
          }
        }
        final logs = doc['logs'] as Map<String, dynamic>;
        expect(
          jsonDeepEquals(logs['S0-J1'], (old['logs'] as Map)['S0-J1']),
          isTrue,
        );
        expect(logs['S0-J1@a1'], isNotNull);
        // Le reste du journal est entier.
        expect(logs.length, (old['logs'] as Map).length);
      }
      final preview = app.previewImport(jsonEncode(file)).preview;
      expect(preview, isNotNull);
      expect(preview!.ignored.hasUserData, isTrue);
      app.dispose();
    });

    test('copie faite : export sans elles (inchangé)', () async {
      final old = withRetiredData(await userDocument(), activeWod: false);
      final app = await launch({_stateKey: jsonEncode(old)});
      expect(app.retiredCopyFailed, isFalse);
      final file =
          jsonDecode(app.exportForFile(appVersion: 'rv2', at: clock))
              as Map<String, dynamic>;
      expect(file.keys.any(kRetiredSections.contains), isFalse);
      expect(
        (file['logs'] as Map).keys.any((k) => '$k'.startsWith('S0-')),
        isFalse,
      );
      expect(app.exportCompact(), startsWith('gz:'));
      app.dispose();
    });
  });

  group('M9 copie locale de la sauvegarde d’origine', () {
    late AppStore app;
    late Map<String, dynamic> o1;
    late Map<String, dynamic> withO2;
    const o2At = '2026-10-01T08:00:00.000';

    setUp(() async {
      app = await launch({});
      await importPr2Nouveau(app);
      await app.flush();
      o1 = Map<String, dynamic>.of(app.programOrigin!);
      expect((await _stored(_originKey))!['at'], o1['at']);
      // Sauvegarde qui porte sa propre origine (O2).
      withO2 = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      withO2['programOrigin'] = {
        ...(withO2['programOrigin'] as Map<String, dynamic>),
        'at': o2At,
      };
    });
    tearDown(() {
      app.debugOriginWriteHook = null;
      app.debugWriteHook = null;
      app.dispose();
    });

    test('copie refusée à l’import : réalignée dès que le stockage '
        'accepte', () async {
      app.debugOriginWriteHook = (_) async => false;
      expect(await app.importAll(jsonEncode(withO2)), isTrue);
      expect(app.programOrigin!['at'], o2At);
      expect((await _stored(_originKey))!['at'], o1['at']);
      app.debugOriginWriteHook = null;
      app.saveSettings();
      await app.flush();
      expect((await _stored(_originKey))!['at'], o2At);
    });

    test('relance après une écriture refusée : l’origine reprise est la '
        'bonne, jamais l’ancienne copie locale', () async {
      app.debugOriginWriteHook = (_) async => false;
      expect(await app.importAll(jsonEncode(withO2)), isTrue);
      app.debugOriginWriteHook = null;
      // Sauvegarde d'avant 6.10.0 (sans origine) : l'origine de l'appareil
      // (O2) est gardée ; l'import s'écrit, l'écriture suivante (qui
      // porte l'origine) est refusée.
      final old = jsonDecode(app.exportAll()) as Map<String, dynamic>
        ..remove('programOrigin');
      final prefs = await SharedPreferences.getInstance();
      app.debugWriteHook = (encoded) async {
        final doc = jsonDecode(_unpack(encoded)) as Map<String, dynamic>;
        if (doc.containsKey('programOrigin')) return false;
        return prefs.setString(_stateKey, encoded);
      };
      expect(await app.importAll(jsonEncode(old)), isTrue);
      await app.flush();
      expect(app.persistenceError.value, isNotNull);
      expect((await _stored(_stateKey))!.containsKey('programOrigin'), isFalse);
      app.debugWriteHook = null;

      final next = await launch();
      expect(next.programOrigin, isNotNull);
      expect(next.programOrigin!['at'], o2At);
      next.dispose();
    });

    test('démarrage : copie locale différente du document réalignée', () async {
      final prefs = await SharedPreferences.getInstance();
      final stale = {...o1, 'at': '2026-09-01T08:00:00.000'};
      await prefs.setString(_originKey, jsonEncode(stale));
      final next = await launch();
      expect(next.programOrigin!['at'], o1['at']);
      expect((await _stored(_originKey))!['at'], o1['at']);
      next.dispose();
    });
  });

  group('aller-retour (magasin synthétique riche, Koach actif)', () {
    late AppStore app;
    var now = DateTime(2026, 10, 19, 7);

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      now = DateTime(2026, 10, 19, 7);
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => now;
      await app.init();
      await importPr2Nouveau(app, firstWeek: 12);
      app.koachNoteInstall();
      await app.koachRefresh();
      // Une séance de Koach commencée, une série validée et notée.
      final j1 = app.program.week(15).day(1)!;
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
      app.consumeLevelUp();
      await app.flush();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      KoachCalcul.isolat = true;
      await app.flush();
      app.dispose();
    });

    test('export → import → export identique', () async {
      final at = DateTime(2026, 10, 19, 8);
      final first = app.exportForFile(appVersion: 'rv2', at: at);
      final a = jsonDecode(first) as Map<String, dynamic>;
      for (final k in [
        'programInstance',
        'programOrigin',
        'athleteProfile',
        'koachEngine',
        'logs',
      ]) {
        expect(a[k], isNotNull, reason: k);
      }
      expect(await app.importBackup(first), ImportStatus.success);
      await app.flush();
      final second = app.exportForFile(appVersion: 'rv2', at: at);
      final b = jsonDecode(second) as Map<String, dynamic>;
      expect(_diff(a, b), isEmpty);
      expect(second, first);
    });

    test('relance sur le document écrit (format de dev7.5.1) : relu et '
        'réécrit à l’identique, rien perdu', () async {
      final at = DateTime(2026, 10, 19, 8);
      final disk = (await _stored(_stateKey))!;
      final export = app.exportForFile(appVersion: 'rv2', at: at);
      app.dispose();
      app = AppStore()..storeClock = () => now;
      await app.init();
      app.saveSettings();
      await app.flush();
      final again = (await _stored(_stateKey))!;
      expect(_diff(disk, again), isEmpty);
      expect(app.exportForFile(appVersion: 'rv2', at: at), export);
    });
  });
}
