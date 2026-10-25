// KB4 (dev7.4.0) : versions, empreinte et asset à jour de Koach 1.0.7 ;
// KB3 (dev7.3.0) : versions, empreinte et asset à jour de Koach 1.0.6
// (`kalis_adapt` 1.0.5) ; le reste du fichier est celui de KB1.
// KB1 (dev7.2.0, pipeline CP, DECISIONS_CP.md C17.29, C17.30) — Koach
// 1.0.5 (`kalis_adapt` 1.0.4) et `kalis_plan` 0.4.2 dans l'application,
// bascule fermée : paquets copiés à l'octet de leurs étiquettes (pour
// `kalis_adapt`, `lib/`, `assets/koach/` et `pubspec.yaml` seulement,
// C17.19.3), asset de paramètres 1.0.5, deux textes de raison neufs,
// journal de Koach d'une version d'avant rejoué par 1.0.5 sans perte,
// export du journal moteur, migration depuis dev7.1.9 (programme de 40
// semaines, S1 à S14), raisons d'un changement de type de jour sur la
// carte « Structure de la semaine ».
//
// Données synthétiques ; horloge injectée ; stockage simulé ; calculs du
// moteur sur place (pas d'isolat dans les tests).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/plan/day_type.dart';
import 'package:streetlift_tracker/plan/plan_texts.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/sha256.dart';

/// Empreinte d'un ensemble de fichiers : SHA-256 de la liste triée des
/// lignes « chemin\0SHA-256 du fichier\n » (même calcul que celui fait sur
/// les étiquettes à la livraison, LIVRAISON_KB1.md § 1).
(int, String) _empreinte(List<String> paths) {
  final files = <String>[];
  for (final p in paths) {
    if (FileSystemEntity.isFileSync(p)) {
      files.add(p);
    } else {
      for (final e in Directory(p).listSync(recursive: true)) {
        if (e is File) files.add(e.path.replaceAll(r'\', '/'));
      }
    }
  }
  files.sort();
  final b = StringBuffer();
  for (final f in files) {
    b.write('$f\u0000${sha256Hex(File(f).readAsBytesSync())}\n');
  }
  return (files.length, sha256Hex(utf8.encode(b.toString())));
}

/// Sauvegarde du propriétaire (programme de 40 semaines commencé le
/// 13/07/2026), journal jusqu'à S[lastWeek]·J7, séries notées à 2 en
/// réserve (comme KM3).
Future<void> _owner(AppStore app, {int lastWeek = 14}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    return w > lastWeek;
  });
  for (final e in logs.entries) {
    final log = (e.value as Map).cast<String, dynamic>();
    final ex = (log['ex'] as Map).cast<String, dynamic>();
    for (final x in ex.values) {
      for (final s in ((x as Map)['sets'] as List)) {
        (s as Map)['rir'] = '2';
      }
    }
  }
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
  expect(await app.importAll(jsonEncode(b)), isTrue);
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: kc.GuidanceMode.assisted,
      ),
    )..consent = 'refused',
  );
}

/// Relevé indépendant de la date du jour : séances, séries validées,
/// records par séance (comme BV11).
Map<String, Object?> _releve(AppStore app) {
  final history = statsHistory(app);
  var sets = 0;
  final records = <String, Object?>{};
  for (final h in history) {
    for (final e in h.session.ex.values) {
      sets += e.sets.where((s) => s.done).length;
    }
    final hits = app.sessionRecords(h.id);
    if (hits.isNotEmpty) {
      records[h.id] = [
        for (final r in hits) [r.exercise, r.kg, r.reps],
      ];
    }
  }
  return {'seances': history.length, 'series': sets, 'records': records};
}

/// Profil street 50 / 50 à six séances (`sampleStreet5050Profile`), en
/// salle complète, poignet très gêné (6/10) : les jours de poussée ne
/// peuvent garder leur schéma (`kalis_plan` 0.4.2, KS1c2).
kc.AthleteProfile kb1WristProfile(kc.CivilDate on) {
  final p = sampleStreet5050Profile(on: on);
  return p.copyWith(
    equipment: <String>{
      ...p.equipment,
      'barre basse',
      'élastique',
      'banc plat',
      'haltères',
      'poulie',
      'anneaux',
      'tapis',
    }.toList(),
    limitations: const <kc.Limitation>[
      kc.Limitation(
        zone: kc.BodyZone.wristHand,
        side: kc.BodySide.both,
        joint: kc.Joint.wrist,
        discomfort: 6,
        since: kc.ConstraintSince.under6Weeks,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 19, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = false;
    clock = DateTime(2026, 10, 19, 9); // lundi, S15·J1
    app = AppStore()..storeClock = () => clock;
    await app.init();
  });
  tearDown(() async {
    debugKoachBasculeAutorisee = false;
    await app.flush();
    app.dispose();
  });

  group('paquets', () {
    test('kalis_adapt 1.0.8 et kalis_plan 0.4.3 (KB6) : copies à l’octet de '
        'leurs étiquettes ; kalis_core 0.4.4 inchangé', () {
      expect(ka.kalisAdaptVersion, '1.0.8');
      expect(kp.kalisPlanVersion, '0.4.3');
      expect(kc.kalisCoreVersion, '0.4.4');
      expect(ko.koachVersion, '1.0.9-ref.1');
      // Empreintes calculées sur `etiquettes/kalis_adapt-v1.0.8` (KB6,
      // `moteurs` 266f9626) et `etiquettes/kalis_plan-v0.4.3` (KB5).
      // (KB1, `etiquettes/kalis_adapt-v1.0.4` : 55 fichiers, 06c8f971… ;
      // KB3, v1.0.5 : 447ffbeb… ; KB4, v1.0.6 : cebaa39f…, kalis_plan
      // 0.4.2 : 9ce7e5a0… ; KB5, v1.0.7 : 55 fichiers, dcf0f322….)
      expect(
        _empreinte(const [
          'packages/kalis_adapt/lib',
          'packages/kalis_adapt/assets/koach',
          'packages/kalis_adapt/pubspec.yaml',
        ]),
        (
          57,
          '5dbdd56c6f69896d2e8a8fbca32f098a6e7632f48ab9cc417940784ccbb8b86b',
        ),
      );
      expect(
        _empreinte(const [
          'packages/kalis_plan/lib',
          'packages/kalis_plan/pubspec.yaml',
        ]),
        (
          32,
          '0f01164123fbf05223a375a81b9d391471425b526dd0d32f58c91108f20eb258',
        ),
      );
    });

    test('kalis_adapt : Dart et assets seulement dans l’arbre (C17.19.3)', () {
      for (final d in const ['reference', 'test', 'tool', 'docs', 'bin']) {
        expect(
          Directory('packages/kalis_adapt/$d').existsSync(),
          isFalse,
          reason: d,
        );
      }
      final assets = [
        for (final e in Directory('packages/kalis_adapt/assets').listSync())
          e.path.split('/').last,
      ];
      expect(assets, ['koach']);
    });

    test('asset de paramètres 1.0.7 (KB4) : SHA-256, déclaration, chemin '
        'lu', () {
      const sha =
          '1a59e6756923ce348378ff356a25b0af4adc8e8114ae9ac1ba53b85c46808dc5';
      expect(kKoachParamsAsset, 'assets/koach/koach_params_1_0_9.json');
      final a = File(kKoachParamsAsset).readAsBytesSync();
      expect(sha256Hex(a), sha);
      expect(ko.koachParametresSha256, sha);
      expect(
        a,
        File(
          'packages/kalis_adapt/assets/koach/koach_params_1_0_9.json',
        ).readAsBytesSync(),
      );
      for (final v in const ['1_0_3', '1_0_5', '1_0_6']) {
        expect(File('assets/koach/koach_params_$v.json').existsSync(), false);
      }
      final p = File('pubspec.yaml').readAsStringSync();
      expect(p, contains('- assets/koach/koach_params_1_0_9.json'));
      expect(p, isNot(contains('koach_params_1_0_3')));
      expect(p, isNot(contains('koach_params_1_0_5')));
      expect(p, isNot(contains('koach_params_1_0_6')));
      expect(p, contains('version: 7.8.0+'));
      final res = KoachRessources.lire(
        File(kKoachParamsAsset).readAsStringSync(),
        File(kKoachFichesAsset).readAsStringSync(),
      );
      expect(res.versionParametres, '1.0.9-ref.1');
    });

    test('deux textes de raison de 1.0.5 (retour progressif)', () {
      expect(
        texteRaisonKoach({
          'code': 'koach.reprise_dose',
          'params': {'zone': 'shoulder'},
        }),
        'Retour progressif : séries limitées sur cet exercice pour ménager '
        'l’épaule.',
      );
      expect(
        texteRaisonKoach({
          'code': 'koach.douleur_retrait',
          'params': {'cause': 'reprise_dose', 'zone': 'elbow'},
        }),
        'Je retire cet exercice : la dose du jour pour le coude est atteinte '
        '(retour progressif).',
      );
    });
  });

  group('bascule fermée', () {
    // KB2 (dev7.2.1) : la constante est ouverte par dérogation (C17.34) ;
    // bascule fermée (repli, tests des lots d'avant) : même comportement
    // qu'en dev7.2.0.
    test('bascule fermée (repli) : le moteur d’avant sert le bloc en '
        'cours', () async {
      expect(kKoachBasculeAutorisee, isTrue);
      await _owner(app);
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNull);
      expect(app.koachTakeoverWeek(), isNull);
      for (final d in app.program.week(15).days) {
        if (d.exercises.isEmpty) continue;
        final a = app.adaptOpen(15, d);
        expect(a, isNotNull);
        expect(a!.koach, isNull, reason: 'J${d.j}');
        break;
      }
      app.koachNoteInstall();
      expect(app.koachEngine.openedOn, isNull);
    });

    test('export du journal moteur avant la bascule (KB2) : versions de '
        '1.0.5, séances au format de walk_forward', () async {
      await _owner(app);
      final exp = (await app.koachJournalExport())!;
      expect(exp['type'], 'journal_moteur');
      expect(exp['version_moteur'], '1.0.9-ref.1');
      expect(exp['version_parametres'], '1.0.9-ref.1');
      expect(exp['sha256_parametres'], ko.koachParametresSha256);
      expect(exp.containsKey('prise_de_main'), isFalse);
      final seances = exp['seances'] as List;
      expect(seances, isNotEmpty);
      var series = 0;
      for (final s in seances) {
        series += ((s as Map)['series'] as List).length;
      }
      expect(series, greaterThan(100));
      expect(jsonDecode(jsonEncode(exp)), isA<Map>());
      // ignore: avoid_print
      print('KB1|export|seances=${seances.length}|series=$series');
    });
  });

  group('session de test : bascule forcée avec Koach 1.0.5', () {
    Future<void> activate() async {
      await _owner(app);
      app.koachForceBascule(civilOf(clock));
      await app.koachRefresh();
      expect(
        app.koachEngine.snap,
        isNotNull,
        reason: '${app.koachEngine.blocked}',
      );
    }

    test(
      'prise de main par 1.0.5 : instantané et paramètres de 1.0.5',
      () async {
        await activate();
        final snap = app.koachEngine.snap!;
        expect(snap.versionMoteur, '1.0.9-ref.1');
        expect(snap.versionParametres, '1.0.9-ref.1');
        expect(snap.shaParametres, ko.koachParametresSha256);
        expect(app.koachLive!.params['version'], '1.0.9-ref.1');
        expect(app.koachEngine.fromWeek, 15);
      },
    );

    test('journal d’une version d’avant (dev7.1.x, Koach 1.0.3) rejoué par '
        '1.0.5 sans perte ; l’export le dit', () async {
      await activate();
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final engine = (doc['koachEngine'] as Map).cast<String, dynamic>();
      final journal = jsonEncode(engine['journal']);
      final versed = jsonEncode(engine['versed']);
      final snap = (engine['snap'] as Map).cast<String, dynamic>();
      snap['version_moteur'] = '1.0.3-ref.1';
      snap['version_parametres'] = '1.0.3-ref.1';
      snap['sha256_parametres'] = 'a' * 64;
      engine['snap'] = snap;
      doc['koachEngine'] = engine;
      // Relu comme au premier lancement de dev7.2.0.
      expect(await app.importAll(jsonEncode(doc)), isTrue);
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.snap, isNotNull);
      expect(e.snap!.versionMoteur, '1.0.3-ref.1');
      expect(jsonEncode(e.journal), journal);
      expect(jsonEncode([...e.versed]..sort()), versed);
      final live = app.koachLive!;
      expect(live.params['version'], '1.0.9-ref.1');
      // Rejeu exact par 1.0.5 : même journal = même état.
      final res = KoachRessources.lire(
        File(kKoachParamsAsset).readAsStringSync(),
        File(kKoachFichesAsset).readAsStringSync(),
      );
      final again = KoachFabrique(
        res,
        e.snap!,
        app.content.catalog!,
      ).rejouer(koachJournalDe(jsonDecode(journal)));
      expect(jsonEncode(again.posterior()), jsonEncode(live.posterior()));
      expect(
        jsonEncode(again.planification!.etat()),
        jsonEncode(live.planification!.etat()),
      );
      final exp = (await app.koachJournalExport())!;
      expect(exp['version_moteur'], '1.0.9-ref.1');
      expect(exp['sha256_parametres'], ko.koachParametresSha256);
      expect((exp['prise_de_main'] as Map)['version_moteur'], '1.0.3-ref.1');
      expect(jsonEncode(exp['journal']), journal);
    });
  });

  group('migration depuis dev7.1.9', () {
    test('programme de 40 semaines, S1 à S14 : mêmes séances, séries et '
        'records ; rien réécrit ; sauvegarde d’origine intacte', () async {
      await _owner(app);
      await app.ensureProgramOrigin();
      await app.flush();
      final before = _releve(app);
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(doc['programOrigin'], isNotNull);
      expect(before['seances'], greaterThan(50));
      // Relancement (même stockage), comme après l'installation.
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      await next.koachRefresh();
      expect(_releve(next), before);
      final after = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      for (final k in const ['logs', 'programStart', 'programOrigin']) {
        expect(jsonEncode(after[k]), jsonEncode(doc[k]), reason: k);
      }
      expect(next.koachEngine.snap, isNull);
      // Bloc en cours servi comme avant (moteur d'avant, pas Koach).
      for (final d in next.program.week(15).days) {
        if (d.exercises.isEmpty) continue;
        expect(next.adaptOpen(15, d)?.koach, isNull, reason: 'J${d.j}');
      }
      await next.flush();
      next.dispose();
      // ignore: avoid_print
      print(
        'KB1|migration|seances=${before['seances']}|series=${before['series']}'
        '|records=${(before['records'] as Map).length}',
      );
    });
  });

  group('carte « Structure de la semaine »', () {
    test('causes lues après le type du jour, dans l’ordre des jours', () {
      kc.Reason r(String code, [Map<String, Object?> p = const {}]) =>
          kc.Reason(code: code, params: p);
      final reasons = [
        r('plan.split_chosen', {'templateId': 'ppl6', 'sessions': 6}),
        r('plan.day_type', {'patterns': 'pull', 'quality': 'force'}),
        r('plan.day_type', {'patterns': 'legs', 'quality': 'force'}),
        r('plan.joint_limitation', {'joint': 'poignet', 'discomfort': 6}),
        r('plan.day_type', {'patterns': 'pull', 'quality': 'endurance'}),
        r('plan.equipment_missing', {'equipment': 'barres parallèles'}),
        r('plan.day_type', {'patterns': 'legs', 'quality': 'endurance'}),
        r('plan.prerequisite_missing', {'exerciseId': 'sw-dips'}),
      ];
      final c = dayTypeChanges(reasons);
      expect(
        [for (final (i, x) in c) '$i ${x.code}'],
        [
          '1 plan.joint_limitation',
          '2 plan.equipment_missing',
          '3 plan.prerequisite_missing',
        ],
      );
      String name(String id) => id == 'sw-dips' ? 'Dips' : id;
      expect(
        dayTypeChangeText(
          'Mardi',
          'Jambes — force',
          c[0].$2,
          exerciseName: name,
        ),
        'Mardi devient « Jambes — force » pour ménager ton poignet (gêne '
        '6/10).',
      );
      expect(
        dayTypeChangeText('Mercredi', null, c[1].$2, exerciseName: name),
        'Mercredi change de type faute de matériel (barres parallèles).',
      );
      expect(
        dayTypeChangeCause(c[2].$2, exerciseName: name),
        'faute d’exercice possible pour l’instant (Dips écarté)',
      );
      expect(dayTypeChanges([r('plan.joint_limitation')]), isEmpty);
      expect(dayTypeChanges(const []), isEmpty);
    });

    test('profil street 50 / 50, poignet très gêné : kalis_plan 0.4.2 change '
        'le type des jours de poussée et dit pourquoi', () {
      clock = DateTime(2026, 10, 5, 9); // lundi
      final saved = app.saveAthleteProfile(
        // Gêne gardée seulement avec le consentement aux données de santé.
        ProfileDraft.of(kb1WristProfile(civilOf(clock)))..consent = 'given',
      );
      expect(saved, isNotNull);
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      expect(app.athlete!.profile.limitations, hasLength(1));
      final plan = c.plan;
      final changes = dayTypeChanges(plan.split?.reasons ?? const []);
      expect(
        changes,
        isNotEmpty,
        reason:
            '${plan.split?.reasons}\n${app.athlete!.profile.equipment}\n'
            '${[for (final d in plan.days) d.slots.map((s) => s.exerciseId).join(' ')].join('\n')}',
      );
      for (final (i, cause) in changes) {
        expect(i, lessThan(plan.days.length));
        expect(cause.code, 'plan.joint_limitation');
        final d = plan.days[i];
        expect(d.type!.patterns, isNot(contains(kc.DayPattern.push)));
        final t = dayTypeChangeText(
          weekdayLabel(d.weekday),
          dayTypeLabel(d.type),
          cause,
          exerciseName: (id) => id,
        );
        expect(t, contains('pour ménager ton poignet (gêne 6/10)'));
        // ignore: avoid_print
        print('KB1|structure|$t');
      }
    });
  });
}
