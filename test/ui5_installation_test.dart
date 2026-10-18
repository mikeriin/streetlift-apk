// UI5 (refonte UI, cahier §6.1, §5.1 « Préférence accent », §7.3) —
// installation de dev6.12.0 par-dessus dev6.11.1 (commit b7996b3f) sans
// perte : stockage d'une installation 6.11.1 (document unique
// `kalis_state_v3`, réglages compris, et copie locale du programme
// d'origine) relu au démarrage ; fichier de sauvegarde 6.11.1 importé
// puis réexporté à l'identique ; anciens identifiants de couleur relus
// vers les palettes ; programme (40 semaines ou programme personnel) et
// journal inchangés.
//
// Provenance des données « 6.11.1 » : produites ici par le code actuel
// puis ramenées au format 6.11.1. Le format d'export n'a pas changé entre
// b7996b3f et la refonte (`git diff b7996b3f HEAD -- lib/persistence.dart
// lib/models.dart` vide ; dans lib/store.dart, seuls changent les
// identifiants de `accent` et le réglage `contrast`, écrit seulement s'il
// est actif). Seul écart rétabli à la main : `accent` porte un ancien
// identifiant (« rouge », « vert »…), comme l'écrivait 6.11.1.
// Clés des réglages et sections : recopiées de b7996b3f
// (`AppSettings.toJson`, `_backupJson`), vérifiées ci-dessous.
//
// Stockage simulé (SharedPreferences en mémoire) ; horloge du magasin
// injectée ; données synthétiques ; aucun réseau.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/kit/kit.dart' show KRoles;
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _stateKey = 'kalis_state_v3';
const _originKey = 'program_origin_v1';
const _recoveryKey = 'kalis_recovery_v1';

/// Sections que `_backupJson` de 6.11.1 (b7996b3f) pouvait écrire.
const _sections6111 = {
  'kalisTrack',
  'format',
  'pilotage',
  'referenceStatus',
  'programStart',
  'logs',
  'settings',
  'userExercises',
  'lastLevel',
  'koach',
  'profile',
  'athleteProfile',
  'programInstance',
  'planProgram',
  'programResume',
  'planEvolution',
  'adapt',
  'programOrigin',
};

/// Clés de `AppSettings.toJson` de 6.11.1 (b7996b3f), `medicalClearance`
/// écrit seulement s'il n'est pas vide ; pas de `contrast`.
const _settingsKeys6111 = [
  'defaultRest',
  'autoTimer',
  'sound',
  'vibration',
  'prepSec',
  'rpe',
  'lb',
  'prefill',
  'wakelock',
  'theme',
  'trackRir',
  'trackVelocity',
  'notifOn',
  'notifHour',
  'notifMinute',
  'notifSkipRest',
  'celebrations',
  'weeklyGoal',
  'title',
  'accent',
];

/// Réglages d'un utilisateur 6.11.1 : chaque valeur différente du défaut,
/// ancienne couleur dominante « rouge ».
const _settings6111 = <String, Object>{
  'defaultRest': 150,
  'autoTimer': false,
  'sound': false,
  'vibration': false,
  'prepSec': 10,
  'rpe': true,
  'lb': true,
  'prefill': false,
  'wakelock': false,
  'theme': 'light',
  'trackRir': true,
  'trackVelocity': true,
  'notifOn': true,
  'notifHour': 18,
  'notifMinute': 45,
  'notifSkipRest': false,
  'celebrations': false,
  'weeklyGoal': 4,
  'title': 'Pionnier',
  'accent': 'rouge',
  'medicalClearance': {'bloc-1#6': '2026-09-20'},
};

/// Anciens identifiants (L5-C) → palettes (cahier §5.1).
const _legacy = [
  ('rouge', 'bordeaux'),
  ('jaune', 'neon'),
  ('vert', 'forest'),
  ('violet', 'violet'),
  ('orange', 'solar'),
  ('turquoise', 'arctic'),
];

final _clock = DateTime(2026, 10, 1, 9);

/// Copie profonde d'un document JSON.
Map<String, dynamic> _copy(Map<String, dynamic> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

/// Document avec la couleur [accent] (sections `settings` et, s'il existe,
/// programme d'origine sauvegardé, qui porte les réglages de son époque).
Map<String, dynamic> _withAccent(
  Map<String, dynamic> doc,
  String accent, {
  bool origin = true,
}) {
  final m = _copy(doc);
  (m['settings'] as Map)['accent'] = accent;
  final o = m['programOrigin'];
  if (origin && o is Map) {
    ((o['backup'] as Map)['settings'] as Map)['accent'] = accent;
  }
  return m;
}

/// Semaines et séances du programme affiché : semaine, bloc, journée,
/// exercices (identifiant et nom).
List<String> _weeks(AppStore s) => [
  for (final w in s.program.weeks)
    for (final d in w.days)
      [
        w.n,
        w.block,
        d.j,
        for (final e in d.exercises) '${e.id}:${e.name}',
      ].join('|'),
];

Map<String, dynamic> _journal(AppStore s) =>
    jsonDecode(
          jsonEncode({for (final e in s.logs.entries) e.key: e.value.toJson()}),
        )
        as Map<String, dynamic>;

/// Contenu complet du stockage simulé (clés de l'application).
Future<Map<String, Object>> _storage() async {
  final p = await SharedPreferences.getInstance();
  return {for (final k in p.getKeys()) k: p.get(k)!};
}

/// Format 6.11.1 vérifié : sections connues, réglages aux clés de 6.11.1,
/// aucune clé `contrast`.
void _expect6111Format(Map<String, dynamic> doc) {
  expect(_sections6111.containsAll(doc.keys), isTrue, reason: '${doc.keys}');
  final settings = doc['settings'] as Map;
  expect(settings.containsKey('contrast'), isFalse);
  expect(settings.keys.toSet(), {
    ..._settingsKeys6111,
    if (settings.containsKey('medicalClearance')) 'medicalClearance',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final opened = <AppStore>[];
  Future<AppStore> launch() async {
    final s = AppStore()..storeClock = () => _clock;
    await s.init();
    opened.add(s);
    return s;
  }

  tearDown(() async {
    for (final s in opened) {
      await s.flush();
      s.dispose();
    }
    opened.clear();
    buildTheme(true);
  });

  group('programme de 40 semaines, journal et réglages de 6.11.1', () {
    // Installation 6.11.1 : programme démarré (calendrier d'origine),
    // 8 semaines saisies, une séance en cours, références, exercice perso,
    // réglages modifiés, couleur « rouge ». Programme d'origine (CI1e)
    // sauvegardé comme 6.11.1 le faisait.
    late Map<String, dynamic> old;
    late Map<String, Object> storage;
    late List<String> weeksBefore;
    late Map<String, double> valuesBefore;
    late int xpBefore, doneBefore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final a = await launch();
      final seed = filledBackup(a);
      final logs = seed['logs'] as Map<String, dynamic>;
      logs.removeWhere(
        (k, _) => int.parse(RegExp(r'^S(\d+)-J').firstMatch(k)![1]!) > 8,
      );
      final week9 = a.program.week(9);
      final day = week9.days.firstWhere((d) => d.exercises.isNotEmpty);
      final ex = day.exercises.first;
      logs[a.sessionKey(9, day.j)] = SessionLog(
        title: 'S9 · J${day.j}',
        exerciseNames: {ex.id: ex.name},
        ex: {
          ex.id: ExerciseLog(
            sets: [
              SetEntry(
                kg: '65',
                reps: '6',
                rir: '1',
                done: true,
                completedAt: '2026-09-14T18:10:00.000',
              ),
              SetEntry(kg: '65', reps: '', rir: ''),
            ],
            note: 'En cours',
          ),
        },
      ).toJson();
      final refs = a.referenceRefs;
      seed['pilotage'] = {'B4': 78.5, refs[1]: 120, refs[2]: 15};
      seed['referenceStatus'] = {
        'B4': 'set',
        refs[1]: 'set',
        refs[2]: 'historic',
      };
      seed['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      seed['settings'] = _settings6111;
      seed['userExercises'] = [
        {'n': 'Planche lean', 'g': 'Épaules', 'eq': 'Poids du corps'},
      ];
      expect(await a.importBackup(jsonEncode(seed)), ImportStatus.success);
      await a.flush();
      // Document tel que 6.11.1 l'écrivait : même format, ancienne couleur.
      old = _withAccent(backupOf(a), 'rouge');
      expect(old['programOrigin'], isA<Map>());
      _expect6111Format(old);
      _expect6111Format(
        (old['programOrigin'] as Map)['backup'] as Map<String, dynamic>,
      );
      weeksBefore = _weeks(a);
      valuesBefore = Map.of(a.values);
      xpBefore = a.xp;
      doneBefore = a.completedCount;
      // Stockage de l'installation 6.11.1 : document compressé et copie
      // locale du programme d'origine au format de 6.11.1 ; copies de
      // récupération de ce test retirées (écrites par le code actuel).
      storage = await _storage()
        ..remove(_recoveryKey)
        ..[_stateKey] = gzText(jsonEncode(old))
        ..[_originKey] = gzText(jsonEncode(old['programOrigin']));
      for (final s in opened) {
        s.dispose();
      }
      opened.clear();
    });

    test('installation par-dessus : démarrage, palette Bordeaux, réglages, '
        'programme, journal et export identiques', () async {
      SharedPreferences.setMockInitialValues(storage);
      final b = await launch();
      // Palette : « rouge » relu en Bordeaux, contraste renforcé éteint.
      expect(b.settings.accent, 'bordeaux');
      expect(b.accentMode.value, 'bordeaux');
      expect(b.contrastMode.value, isFalse);
      expect(b.themeMode.value, 'light');
      final spec = KAccentSpec.byId(b.accentMode.value);
      expect(spec, same(KAccentSpec.bordeaux));
      buildTheme(b.themeMode.value == 'dark', spec, b.contrastMode.value);
      expect(SL.accentSpec, same(KAccentSpec.bordeaux));
      expect(SL.contrast, isFalse);
      // Réglages : toutes les autres valeurs relues telles quelles.
      final expectedSettings = Map<String, Object>.of(_settings6111)
        ..['accent'] = 'bordeaux';
      expect(
        jsonDecode(jsonEncode(b.settings.toJson())),
        equals(expectedSettings),
      );
      // Programme et journal inchangés.
      expect(b.program.start, DateTime(2026, 7, 13));
      expect(b.startOrigin, 'migration');
      expect(_weeks(b), weeksBefore);
      expect(_journal(b), equals(old['logs']));
      expect(b.values, valuesBefore);
      expect(b.refProvenance(b.referenceRefs[2]), 'historic');
      expect(b.userExercises, old['userExercises']);
      expect(b.completedCount, doneBefore);
      expect(b.xp, xpBefore);
      // Export : document de 6.11.1, seule la couleur relue change ; aucune
      // clé `contrast`.
      final expected = _withAccent(old, 'bordeaux', origin: false);
      final exported = jsonDecode(b.exportAll()) as Map<String, dynamic>;
      expect(exported, equals(expected));
      expect((exported['settings'] as Map).containsKey('contrast'), isFalse);
      // Deuxième lancement : rien n'a bougé.
      await b.flush();
      final c = await launch();
      expect(jsonDecode(c.exportAll()), equals(expected));
      expect(c.accentMode.value, 'bordeaux');
      expect(_weeks(c), weeksBefore);
    });

    test('fichier de sauvegarde 6.11.1 : aperçu, import puis export '
        'identiques', () async {
      SharedPreferences.setMockInitialValues({});
      final d = await launch();
      final file = jsonEncode({
        ...old,
        'exportedAt': '2026-09-30T18:00:00.000',
        'appVersion': '6.11.1+114',
      });
      final expected = _withAccent(old, 'bordeaux', origin: false);
      for (final raw in [file, gzText(file)]) {
        final checked = d.previewImport(raw);
        expect(checked.status, ImportStatus.success);
        final preview = checked.preview!;
        expect(preview.appVersion, '6.11.1+114');
        expect(preview.programStart, DateTime(2026, 7, 13));
        expect(preview.programSessions, doneBefore);
        expect(await d.applyImport(preview), ImportStatus.success);
        expect(d.settings.accent, 'bordeaux');
        expect(d.accentMode.value, 'bordeaux');
        expect(jsonDecode(d.exportAll()), equals(expected));
        final again =
            jsonDecode(d.exportForFile(appVersion: '6.12.0', at: _clock))
                as Map<String, dynamic>;
        expect(again.remove('exportedAt'), _clock.toIso8601String());
        expect(again.remove('appVersion'), '6.12.0');
        expect(again, equals(expected));
        expect(_weeks(d), weeksBefore);
        expect(_journal(d), equals(old['logs']));
      }
    });

    test('anciens identifiants de couleur : relus, jamais refusés', () async {
      SharedPreferences.setMockInitialValues({});
      final d = await launch();
      for (final (id, palette) in _legacy) {
        expect(normalizeAccent(id), palette);
        expect(normalizePaletteId(id), palette);
        expect(KAccentSpec.byId(id).id, palette);
        expect(KRoles.of(id, dark: true), same(KRoles.of(palette, dark: true)));
        final doc = _withAccent(old, id);
        expect(
          await d.importBackup(jsonEncode(doc)),
          ImportStatus.success,
          reason: id,
        );
        expect(d.settings.accent, palette, reason: id);
        expect(d.accentMode.value, palette, reason: id);
        expect(KAccentSpec.byId(d.accentMode.value).id, palette);
        expect(
          jsonDecode(d.exportAll()),
          equals(_withAccent(doc, palette, origin: false)),
          reason: id,
        );
      }
      // Absent, inconnu ou d'un autre type : Bordeaux, sauvegarde acceptée.
      for (final value in <Object?>[null, 'magenta', 'ROUGE', 7]) {
        final doc = _copy(old);
        final settings = doc['settings'] as Map;
        if (value == null) {
          settings.remove('accent');
        } else {
          settings['accent'] = value;
        }
        expect(
          await d.importBackup(jsonEncode(doc)),
          ImportStatus.success,
          reason: '$value',
        );
        expect(d.settings.accent, 'bordeaux', reason: '$value');
        expect(d.accentMode.value, 'bordeaux', reason: '$value');
        final out = jsonDecode(d.exportAll()) as Map<String, dynamic>;
        expect((out['settings'] as Map)['accent'], 'bordeaux');
        expect(
          out,
          equals(_withAccent(doc, 'bordeaux', origin: false)),
          reason: '$value',
        );
      }
    });
  });

  test('programme personnel (kalis_plan) de 6.11.1 : semaines, séances, '
      'journal et couleur « vert » relus', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await launch();
    p.seedSampleAthleteProfile();
    final c = PlanStore(p).newPlanCreation(journal: false)!;
    c.start();
    c.createPass2();
    PlanStore(p).applyPlanCreation(c);
    expect(p.planProgram, isNotNull);
    final first = p.program.weeks.first.days.firstWhere(
      (d) => d.exercises.isNotEmpty,
    );
    p.markSessionDone(p.program.weeks.first.n, first.j, true);
    p.settings
      ..theme = 'system'
      ..defaultRest = 120;
    p.saveSettings();
    await p.flush();
    final old = _withAccent(backupOf(p), 'vert');
    expect(old['planProgram'], isA<Map>());
    expect(old['athleteProfile'], isA<Map>());
    _expect6111Format(old);
    final weeksBefore = _weeks(p);
    final startBefore = p.program.start;
    final storage = await _storage()
      ..remove(_recoveryKey)
      ..[_stateKey] = gzText(jsonEncode(old));
    p.dispose();
    opened.remove(p);

    SharedPreferences.setMockInitialValues(storage);
    final q = await launch();
    expect(q.settings.accent, 'forest');
    expect(q.accentMode.value, 'forest');
    expect(KAccentSpec.byId(q.accentMode.value), same(KAccentSpec.forest));
    expect(q.themeMode.value, 'system');
    expect(q.settings.defaultRest, 120);
    expect(q.planProgram, isNotNull);
    expect(q.program.start, startBefore);
    expect(_weeks(q), weeksBefore);
    expect(q.isDone(q.program.weeks.first.n, first.j), isTrue);
    expect(_journal(q), equals(old['logs']));
    expect(
      jsonDecode(q.exportAll()),
      equals(_withAccent(old, 'forest', origin: false)),
    );
  });
}
