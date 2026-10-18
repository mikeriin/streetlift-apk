// KM3 (dev7.0.0, pipeline CP, DECISIONS_CP.md C13, C17.14) — Koach 1.0
// dans l'application : assets, bascule, prise de main, séance servie
// (`seance_debut`, `plan(seance)`, `plan(serie)`, `seance_fin`), charge
// fixe (C15), suggestions acceptées ou refusées, hors modèle et
// diagnostic, arrêt d'urgence et réactivation, rejeu exact, export du
// journal moteur et walk-forward, temps de calcul.
//
// Données synthétiques ; horloge injectée ; stockage simulé ; calculs du
// moteur sur place (pas d'isolat dans les tests).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart' show adaptKgField;
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/sha256.dart';

/// Sauvegarde du propriétaire (programme commencé le 13/07/2026), journal
/// jusqu'à S[lastWeek]·J[lastJ], séries notées à 2 en réserve.
Future<void> _owner(AppStore app, {int lastWeek = 13, int lastJ = 7}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ);
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

/// Valide la série [i] de [e] (répétitions, flammes) et demande la cible
/// suivante, comme l'écran de séance.
void _validate(
  AppStore app,
  int week,
  int j,
  Exercise e,
  int i,
  String reps,
  int flames,
) {
  final base = app.program.week(week).day(j)!;
  final log = app.exLog(week, j, e);
  app.adaptPrefill(week, j, e, log);
  log.sets[i].reps = reps;
  log.sets[i].flames = flames;
  expect(app.toggleSet(log, i, app.logSpec(e)).ok, isTrue);
  app.koachAfterSet(week, base, e, i);
}

/// Exercices servis de la journée.
List<Exercise> _served(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  return app.adaptDay(week, base, a).exercises;
}

/// Journée de la semaine avec des exercices, à partir de [from].
int _dayWithWork(AppStore app, int week, [int from = 1]) {
  for (final d in app.program.week(week).days) {
    if (d.j >= from && d.exercises.isNotEmpty) return d.j;
  }
  fail('aucune journée');
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
    debugDisableFixedLoad = false;
  });
  tearDown(() async {
    debugKoachBasculeAutorisee = false;
    await app.flush();
    app.dispose();
  });

  group('assets et paquet', () {
    test('assets de Koach = copies à l’octet du paquet, SHA-256 attendus', () {
      for (final name in const [
        'koach_params_1_0_5.json',
        'vecteurs_qualites_v1.json',
      ]) {
        final a = File('assets/koach/$name').readAsBytesSync();
        final p = File(
          'packages/kalis_adapt/assets/koach/$name',
        ).readAsBytesSync();
        expect(a, p, reason: name);
      }
      expect(
        sha256Hex(
          File('assets/koach/koach_params_1_0_5.json').readAsBytesSync(),
        ),
        ko.koachParametresSha256,
      );
      expect(
        sha256Hex(
          File('assets/koach/vecteurs_qualites_v1.json').readAsBytesSync(),
        ),
        ko.koachFichesSha256,
      );
      final res = KoachRessources.lire(
        File('assets/koach/koach_params_1_0_5.json').readAsStringSync(),
        File('assets/koach/vecteurs_qualites_v1.json').readAsStringSync(),
      );
      expect(res.fiches.length, 1039);
      // ignore: avoid_print
      print('KM3|paquet|${ko.koachVersion}|${res.versionParametres}');
    });

    test('pubspec : assets de Koach déclarés, version 7.2.0 (KB1)', () {
      final p = File('pubspec.yaml').readAsStringSync();
      expect(p, contains('- assets/koach/koach_params_1_0_5.json'));
      expect(p, contains('- assets/koach/vecteurs_qualites_v1.json'));
      expect(p, contains('version: 7.2.0+'));
    });
  });

  group('bascule', () {
    test(
      'fermée dans ce build : le moteur d’avant sert le bloc en cours',
      () async {
        await _owner(app);
        await app.koachRefresh();
        expect(app.koachEngine.snap, isNull);
        expect(app.koachTakeoverWeek(), isNull);
        final j = _dayWithWork(app, 15);
        final a = app.adaptOpen(15, app.program.week(15).day(j)!);
        expect(a, isNotNull);
        expect(a!.koach, isNull);
      },
    );

    test('date : 23/11/2026 si installé au plus tard le 16/11, sinon '
        '04/01/2027 ; prise de main au début du bloc (S20)', () async {
      await _owner(app);
      app.koachNoteInstall();
      expect(app.koachEngine.installedOn, '2026-10-19');
      expect(app.koachBasculeDate, kc.CivilDate(2026, 11, 23));
      app.koachEngine.installedOn = '2026-11-17';
      expect(app.koachBasculeDate, kc.CivilDate(2027, 1, 4));
      app.koachEngine.installedOn = '2026-10-19';
      debugKoachBasculeAutorisee = true;
      expect(app.koachTakeoverWeek(), isNull); // pas avant le 23/11
      clock = DateTime(2026, 11, 23, 8);
      expect(app.koachTakeoverWeek(), 20);
      clock = DateTime(2026, 11, 25, 8);
      expect(app.koachTakeoverWeek(), 20);
    });
  });

  group('Koach sert le programme de 40 semaines (bascule forcée)', () {
    Future<void> activate() async {
      await _owner(app, lastWeek: 14, lastJ: 7);
      app.koachForceBascule(civilOf(clock));
      await app.koachRefresh();
      expect(
        app.koachEngine.snap,
        isNotNull,
        reason: '${app.koachEngine.blocked}',
      );
    }

    test(
      'prise de main : historique versé sans plan, référence, rejeu exact',
      () async {
        await activate();
        final e = app.koachEngine;
        expect(e.fromWeek, 15);
        expect(e.closed, 14);
        expect(e.versed, isNotEmpty);
        final types = [for (final x in e.journal) x['type']];
        expect(types.where((t) => t == 'reference').length, 1);
        expect(types, isNot(contains('plan')));
        expect(
          types.lastIndexOf('seance_fin'),
          lessThan(types.indexOf('reference')),
        );
        expect(types.where((t) => t == 'semaine_fin').length, 14);
        // Rejeu exact : même journal (aller-retour JSON) = même état.
        final live = app.koachLive!;
        final res = KoachRessources.lire(
          File('assets/koach/koach_params_1_0_5.json').readAsStringSync(),
          File('assets/koach/vecteurs_qualites_v1.json').readAsStringSync(),
        );
        final fab = KoachFabrique(res, e.snap!, app.content.catalog!);
        final again = fab.rejouer(
          koachJournalDe(jsonDecode(jsonEncode(e.journal))),
        );
        expect(jsonEncode(again.posterior()), jsonEncode(live.posterior()));
        expect(
          jsonEncode(again.planification!.etat()),
          jsonEncode(live.planification!.etat()),
        );
        expect(
          jsonEncode(again.surveillance!.etatComplet()),
          jsonEncode(live.surveillance!.etatComplet()),
        );
        expect(jsonEncode(again.dual!.etat()), jsonEncode(live.dual!.etat()));
        expect(
          jsonEncode(again.adherence!.etat()),
          jsonEncode(live.adherence!.etat()),
        );
        // ignore: avoid_print
        print(
          'KM3|prise_de_main|evenements=${e.journal.length}|'
          'seances=${e.versed.length}|'
          'temps=${app.koachTemps.toJson()}',
        );
      },
    );

    test(
      'séance servie : aperçu, début réel, cible par série, fin versée',
      () async {
        await activate();
        final j = _dayWithWork(app, 15);
        final base = app.program.week(15).day(j)!;
        final a = app.adaptOpen(15, base)!;
        expect(a.koach?['state'], 'preview');
        expect(app.koachPending(15, j), isTrue);
        expect(await app.koachStart(15, base), isTrue);
        final open = app.sessionAdapt(15, j)!;
        expect(open.koach?['state'], 'open');
        final n0 = app.koachEngine.journal.length;
        // Première série de chaque exercice servi : cible de Koach, puis
        // séries validées.
        var done = 0;
        for (final e in _served(app, 15, j).take(2)) {
          final log = app.exLog(15, j, e);
          app.adaptPrefill(15, j, e, log);
          final g = app.adaptGoal(15, j, e, 0);
          expect(g, isNotNull, reason: e.name);
          for (var i = 0; i < log.sets.length && i < 2; i++) {
            final goal = app.adaptGoal(15, j, e, i)!;
            _validate(app, 15, j, e, i, '${goal.prefill ?? 5}', 8);
            done++;
          }
        }
        expect(done, greaterThan(0));
        final types = [
          for (final x in app.koachEngine.journal.sublist(n0)) x['type'],
        ];
        expect(types, contains('plan'));
        expect(types, contains('serie'));
        app.markSessionDone(15, j, true);
        expect(app.koachEngine.versed, contains(app.sessionKey(15, j)));
        final last = app.koachEngine.journal.lastWhere(
          (x) => x['type'] == 'seance_fin',
        );
        expect(((last['seance'] as Map)['sets'] as List), isNotEmpty);
        expect(app.sessionAdapt(15, j)!.koach?['state'], 'closed');
        // Prévision de la prochaine fois (C15.4) : copie du moteur.
        for (
          var i = 0;
          i < 200 && app.sessionAdapt(15, j)!.koach?['prevision'] == null;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(app.sessionAdapt(15, j)!.koach?['prevision'], isA<Map>());
        final sum = app.adaptSummary(15, base)!;
        expect(sum.exercises.any((e) => e.next != null), isTrue);
        // ignore: avoid_print
        print(
          'KM3|prevision|${jsonEncode(app.sessionAdapt(15, j)!.koach?['prevision'])}',
        );
        // ignore: avoid_print
        print('KM3|seance|temps=${app.koachTemps.toJson()}');
      },
    );

    test(
      'suggestion refusée « trop lourd » : décision versée après la fin',
      () async {
        await activate();
        final j = _dayWithWork(app, 15);
        final base = app.program.week(15).day(j)!;
        app.adaptOpen(15, base);
        expect(await app.koachStart(15, base), isTrue);
        final e = _served(app, 15, j).firstWhere(
          (x) => x.engine && x.slotId != null && !x.slotId!.endsWith('.t'),
        );
        final log = app.exLog(15, j, e);
        app.adaptPrefill(15, j, e, log);
        // Proposition posée sur la cible de la première série (forme du
        // moteur), comme après une hausse de charge.
        final a = app.sessionAdapt(15, j)!;
        final st = Map<String, Object?>.of(a.koach!);
        final cibles = Map<String, Object?>.of(
          (st['cibles'] as Map).cast<String, Object?>(),
        );
        final m = Map<String, Object?>.of(
          (cibles[e.slotId] as Map? ?? const {}).cast<String, Object?>(),
        );
        m['0'] = {
          ...((m['0'] as Map?) ?? const {}).cast<String, Object?>(),
          'loadKg': 40.0,
          'proposition': {
            'type': 'charge_plus',
            'depart': 37.5,
            'cible': 40.0,
            'pas': 2.5,
            'ampleur': 1.0,
            'paliers': [40.0],
            'moment': 'debut_de_seance',
          },
        };
        cibles[e.slotId!] = m;
        st['cibles'] = cibles;
        app.sessionLog(15, j).adapt = a
            .copyWith(koach: st)
            .toJson()
            .cast<String, dynamic>();
        final s = app.koachSuggestion(15, j, e);
        expect(s?.type, 'charge_plus');
        app.koachDecide(15, base, e, false, reason: 'too_heavy');
        expect(app.koachSuggestion(15, j, e)?.decided, 'non');
        // Charge d'avant pré-remplie.
        expect(log.sets.first.kg, adaptKgField(37.5));
        app.markSessionDone(15, j, true);
        final d = app.koachEngine.journal.lastWhere(
          (x) => x['type'] == 'decision' && x['proposition'] != null,
        );
        expect(d['accepte'], isFalse);
        expect(d['raison'], 'too_heavy');
        final i = app.koachEngine.journal.indexOf(d);
        final fin = app.koachEngine.journal.lastIndexWhere(
          (x) => x['type'] == 'seance_fin',
        );
        expect(i, greaterThan(fin));
      },
    );

    test('arrêt d’urgence : écrit servi, rien perdu ; réactivation par '
        'rejeu et rattrapage', () async {
      await activate();
      final before = app.koachEngine.journal.length;
      app.koachStop();
      expect(app.koachEngine.stop, isNotNull);
      final j = _dayWithWork(app, 15);
      final base = app.program.week(15).day(j)!;
      expect(app.koachServesDay(15, j), isFalse);
      expect(app.adaptOpen(15, base), isNull);
      // Séance faite pendant l'arrêt (telle qu'écrite).
      final e = base.exercises.first;
      final log = app.exLog(15, j, e);
      log.sets.first.reps = '5';
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.markSessionDone(15, j, true);
      expect(app.koachEngine.journal.length, before);
      await app.koachResume();
      expect(app.koachEngine.stop, isNull);
      expect(app.koachEngine.versed, contains(app.sessionKey(15, j)));
      expect(app.koachEngine.journal.length, greaterThan(before));
    });

    test('calculs dans un isolat, comme sur le téléphone : prise de main, '
        'rattrapage, début de séance, nouvelle référence, prévision, arrêt '
        'et réactivation (rien d’inenvoyable dans les messages)', () async {
      KoachCalcul.isolat = true;
      addTearDown(() => KoachCalcul.isolat = false);
      await activate();
      expect(app.koachLive, isNotNull);
      expect(app.koachRuntimeError, isNull);
      // Lundi suivant : rattrapage (semaine_fin, séances manquées).
      clock = DateTime(2026, 10, 26, 9); // lundi, S16·J1
      await app.koachRefresh();
      expect(app.koachRuntimeError, isNull);
      expect(app.koachLive, isNotNull);
      expect(app.koachEngine.closed, 15);
      final j = _dayWithWork(app, 16);
      final base = app.program.week(16).day(j)!;
      app.adaptOpen(16, base);
      expect(await app.koachStart(16, base), isTrue);
      expect(app.koachOpen(16, j), isTrue);
      final e = _served(app, 16, j).firstWhere((x) => x.engine);
      _validate(app, 16, j, e, 0, '5', 8);
      app.markSessionDone(16, j, true);
      await app.koachRefresh();
      expect(app.koachEngine.versed, contains(app.sessionKey(16, j)));
      // Nouvelle référence (retour au programme d'origine, bloc réécrit).
      final refs = app.koachEngine.journal
          .where((x) => x['type'] == 'reference')
          .length;
      await app.koachNewReference();
      expect(app.koachRuntimeError, isNull);
      expect(
        app.koachEngine.journal.where((x) => x['type'] == 'reference').length,
        refs + 1,
      );
      // Arrêt puis réactivation : rejeu et rattrapage dans l'isolat.
      app.koachStop();
      await app.koachResume();
      expect(app.koachEngine.stop, isNull);
      expect(app.koachLive, isNotNull);
      expect(app.koachRuntimeError, isNull);
      // ignore: avoid_print
      print('KM3|isolat|${app.koachTemps.toJson()}');
    });

    test('lundi suivant : séances manquées, fin de semaine, replanification '
        '(≤ 10 s) ; hors modèle après deux semaines sans séance', () async {
      await activate();
      clock = DateTime(2026, 11, 2, 9); // lundi, S17·J1
      await app.koachRefresh();
      final types = [for (final x in app.koachEngine.journal) x['type']];
      expect(types, contains('seance_manquee'));
      expect(app.koachEngine.closed, 16);
      final t = app.koachTemps.resume['replanification'];
      expect(t, isNotNull);
      expect(t!.max, lessThan(10000));
      // ignore: avoid_print
      print(
        'KM3|replanification|${app.koachTemps.toJson()}|'
        'hors_modele=${app.koachNeedsDiagnostic}|${app.koachAlertCauses}',
      );
      if (app.koachNeedsDiagnostic) {
        final qs = app.koachQuestions(const {});
        expect(qs, isNotEmpty);
        expect(qs.first['code'], 'cause');
        final j = _dayWithWork(app, 17);
        final base = app.program.week(17).day(j)!;
        app.adaptOpen(17, base);
        expect(
          await app.koachStart(17, base, diagnostic: {'cause': 'fatigue'}),
          isTrue,
        );
        final d = app.koachEngine.journal.lastWhere(
          (x) => x['type'] == 'decision' && x['diagnostic'] != null,
        );
        expect((d['diagnostic'] as Map)['cause'], 'fatigue');
        expect(app.koachLive!.surveillance!.reponses, isNotEmpty);
      }
    });

    test('export du journal moteur (format de walk_forward) et rejeu '
        'walk-forward', () async {
      await activate();
      final exp = (await app.koachJournalExport())!;
      expect(exp['type'], 'journal_moteur');
      expect(exp['version_moteur'], ko.koachVersion);
      expect(exp['sha256_parametres'], ko.koachParametresSha256);
      final seances = exp['seances'] as List;
      expect(seances, isNotEmpty);
      final s0 = seances.first as Map;
      for (final k in const [
        'cle',
        'semaine',
        'jour',
        'avant',
        'debut',
        'series',
        'meta',
        'fin',
      ]) {
        expect(s0.containsKey(k), isTrue, reason: k);
      }
      expect((s0['series'] as List).length, (s0['meta'] as List).length);
      final wf = (await app.koachWalkForward(depuis: 1))!;
      expect(wf['seances_rejouees'], seances.length);
      // ignore: avoid_print
      print('KM3|walk_forward|${jsonEncode(wf['A_une_seance_d_avance'])}');
    });

    test('sauvegarde : section koachEngine relue, journal rejouable ; '
        'ancienne sauvegarde sans la section : rien ne change', () async {
      await activate();
      final text = app.exportAll();
      final m = jsonDecode(text) as Map<String, dynamic>;
      expect(m['koachEngine'], isA<Map>());
      final back = KoachEngineData.fromJson(m['koachEngine']);
      expect(back.journal.length, app.koachEngine.journal.length);
      expect(back.snap!.lundi, '2026-07-13');
      expect(back.fromWeek, 15);
      m.remove('koachEngine');
      expect(await app.importAll(jsonEncode(m)), isTrue);
      expect(app.koachEngine.snap, isNull);
    });

    test('charge fixe (C15) au-dessus de Koach : ligne écrite servie à sa '
        'charge', () async {
      await activate();
      final imp = app.importedProgram!;
      String? key;
      for (final k in imp.fixedLoad.keys) {
        final w = int.parse(k.split('|').first);
        if (w == 15) {
          key = k;
          break;
        }
      }
      expect(key, isNotNull);
      final slot = key!.substring(key.indexOf('|') + 1);
      final kg = imp.fixedLoad[key]!.$2;
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
      final e = _served(app, 15, j).firstWhere((x) => x.slotId == slot);
      final log = app.exLog(15, j, e);
      app.adaptPrefill(15, j, e, log);
      final g = app.adaptGoal(15, j, e, 0)!;
      expect(g.kg, kg);
      // ignore: avoid_print
      print('KM3|charge_fixe|$slot|$kg|${g.low}-${g.high}');
    });

    test('textes : aucune raison affichée en code brut', () async {
      await activate();
      clock = DateTime(2026, 11, 2, 9);
      await app.koachRefresh();
      final j = _dayWithWork(app, 17);
      final base = app.program.week(17).day(j)!;
      app.adaptOpen(17, base);
      await app.koachStart(17, base, diagnostic: {'cause': 'rien'});
      final lines = [
        ...app.koachSessionReasons(17, j, max: 50),
        for (final e in _served(app, 17, j))
          if (app.koachReasonLine(17, j, e) case final l?) l,
      ];
      for (final l in lines) {
        expect(l, isNot(contains('koach.')));
        expect(l, isNot(contains('{')));
        expect(l.trim(), isNotEmpty);
      }
      // ignore: avoid_print
      print('KM3|raisons|${lines.length}|${lines.take(3).join(' / ')}');
    });

    test('migration : la prise de main ne réécrit aucune séance ni série ; '
        'sauvegarde d’origine ; retour au programme d’origine', () async {
      await _owner(app, lastWeek: 14, lastJ: 7);
      final before = jsonEncode(
        (jsonDecode(app.exportAll()) as Map<String, dynamic>)['logs'],
      );
      app.koachForceBascule(civilOf(clock));
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNotNull);
      final after = jsonEncode(
        (jsonDecode(app.exportAll()) as Map<String, dynamic>)['logs'],
      );
      expect(after, before);
      expect(app.programOrigin, isNotNull);
      expect(app.canRestoreProgramOrigin, isTrue);
      final n = app.koachEngine.journal.length;
      app.restoreProgramOrigin();
      await app.koachRefresh();
      // Journal gardé, nouvelle référence seulement si les blocs changent.
      expect(app.koachEngine.journal.length, greaterThanOrEqualTo(n));
      expect(app.koachEngine.snap, isNotNull);
    });

    test('chaque semaine de S15 à S20 : séance servie par Koach avec ses '
        'exercices', () async {
      await activate();
      for (var w = 15; w <= 20; w++) {
        clock = DateTime(2026, 10, 19 + 7 * (w - 15), 9);
        await app.koachRefresh();
        final j = _dayWithWork(app, w);
        clock = DateTime(2026, 10, 19 + 7 * (w - 15) + j - 1, 9);
        await app.koachRefresh();
        final base = app.program.week(w).day(j)!;
        app.adaptOpen(w, base);
        expect(await app.koachStart(w, base), isTrue, reason: 'S$w·J$j');
        final served = _served(app, w, j).where((e) => e.engine).toList();
        expect(served, isNotEmpty, reason: 'S$w·J$j');
        app.markSessionDone(w, j, true);
        // ignore: avoid_print
        print('KM3|semaine|S$w·J$j|${served.length}');
      }
    });

    test('reprise après quatre semaines sans séance : ce que Koach sert '
        '(relevé)', () async {
      await activate();
      clock = DateTime(2026, 11, 16, 9); // lundi, S19·J1
      await app.koachRefresh();
      final j = _dayWithWork(app, 19);
      clock = DateTime(2026, 11, 16 + j - 1, 9);
      await app.koachRefresh();
      final base = app.program.week(19).day(j)!;
      app.adaptOpen(19, base);
      expect(
        await app.koachStart(19, base, diagnostic: {'cause': 'rien'}),
        isTrue,
      );
      final served = _served(app, 19, j).where((e) => e.engine).toList();
      final raisons = app.sessionAdapt(19, j)!.koach?['raisons'] as List?;
      // ignore: avoid_print
      print(
        'KM3|reprise|S19·J$j|servis=${served.length}|'
        'ecrits=${base.exercises.length}|'
        'raisons=${jsonEncode([for (final r in raisons ?? const []) (r as Map)['code']])}',
      );
    });
  });
}
