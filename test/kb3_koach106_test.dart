// KB4 (dev7.4.0, C17.40) : les tests propres à Koach 1.0.6 (garde des
// principaux seulement, scénario C17.37) sont remplacés par
// test/kb4_koach107_test.dart ; restent les textes, les rôles, l'ordre des
// raisons, les raisons gardées, les séances manquées, le passage depuis
// dev7.2.4 et le programme créé.
// KB3 (dev7.3.0, pipeline CP, DECISIONS_CP.md C17.39) — Koach 1.0.6
// (`kalis_adapt` 1.0.5) dans l'application :
//
// - rôle de l'emplacement donné à chaque item de `reste_semaine` et des
//   séances manquées (le retour gradué coupe les accessoires d'abord et
//   garde le plancher des principaux) ;
// - garde de la séance (`koachGardeSeance`) pour les principaux seulement :
//   un accessoire ou un secondaire retiré par Koach reste retiré, raison
//   affichée ; un principal absent du servi est servi tel qu'écrit ;
// - raisons : séries réduites (« 3 séries au lieu de 6 ») et retrait
//   (« Je retire … aujourd’hui ») dits ; affichage indépendant de l'ordre
//   des raisons du moteur ;
// - scénario C17.37 sur le programme importé PR2 synthétique (six séances
//   par semaine en PPL, départ affiché S15, pull-over « chest » ajouté au
//   lundi de tirage) : muscle-up lesté et traction lestée servis par
//   Koach, l'accessoire « chest » retiré d'abord ;
// - données : passage depuis dev7.2.4 (prise de main de Koach 1.0.5)
//   sans perte, séances faites jamais réécrites, programme d'origine
//   intact (C11.2), pas de nouvelle prise de main.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_journal.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

Map<String, Object?> _r(String code, String ex) => {
  'code': code,
  'params': {'exercice': ex},
};

/// Semaine type PR2 avec un pull-over (accessoire qui crédite « chest »)
/// au lundi de tirage, après la traction lestée et ses pompes.
Map<String, dynamic> _semaineAvecPullOver() {
  final s = pr2Semaine();
  final j1 = (s['days'] as List).first as Map<String, dynamic>;
  final ex = (j1['exercises'] as List).cast<Map<String, dynamic>>();
  ex.insert(3, {
    'id': 'NA-S15J1-08',
    'name': 'Pull-over haltère',
    'sets': {'type': 'text', 'value': '3×12'},
    'intensity': 'RIR 2',
    'load': {'type': 'acc', 'ref': 'B43', 'dayReps': 12, 'step': 2.0},
    'rest': '90 s',
    'restSec': 90,
    'tempo': 'Contrôlé',
    'cue': 'Accessoire du test KB3 (données synthétiques).',
    'main': false,
    'prevention': false,
    'catalogId': 'mu-pull-over-haltere',
  });
  j1['exercises'] = ex;
  return s;
}

/// Dernier début de séance versé au journal de Koach.
Map<String, Object?> _debut(AppStore app) =>
    app.koachEngine.journal.lastWhere((x) => x['type'] == 'seance_debut');

/// Contexte du dernier début de séance.
Map<String, Object?> _contexte(AppStore app) =>
    ((_debut(app)['contexte'] as Map?) ?? const {}).cast<String, Object?>();

/// Section de la sauvegarde exportée.
String _section(AppStore app, String key) =>
    jsonEncode((jsonDecode(app.exportAll()) as Map<String, dynamic>)[key]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paquet', () {
    // KB4 : versions, empreinte et asset de Koach 1.0.7 : test/kb1_koach105_test.dart
    // et test/kb4_koach107_test.dart.
    test('textes 1.0.6 : séries réduites (« au lieu de »), retrait du '
        'jour', () {
      final reduit = texteRaisonKoach({
        'code': 'koach.retour_gradue',
        'params': {
          'exercice': 'sl-muscle-up-leste',
          'groupe': 'chest',
          'series': 3,
          'ecrites': 6,
        },
      }, nomExercice: (_) => 'Muscle-up lesté');
      expect(reduit, startsWith('3 séries au lieu de 6 sur'));
      expect(reduit, contains('Muscle-up lesté'));
      final retrait = texteRaisonKoach({
        'code': 'koach.retour_gradue',
        'params': {
          'exercice': 'mu-pull-over-haltere',
          'groupe': 'chest',
          'series': 0,
          'ecrites': 3,
        },
      }, nomExercice: (_) => 'Pull-over');
      expect(retrait, startsWith('Je retire'));
      expect(retrait, contains('Pull-over'));
      expect(retrait, contains('aujourd’hui'));
      // Ligne au départ chronométré servie telle qu'écrite (PR8).
      expect(
        koachTexteReduitEcrit({
          'code': 'koach.retour_gradue',
          'params': {'series': 3, 'ecrites': 6},
        }),
        contains('3 séries sur 6'),
      );
      expect(
        koachTexteReduitEcrit({
          'code': 'koach.retour_gradue',
          'params': {'series': 0, 'ecrites': 6},
        }),
        isNull,
      );
    });
  });

  group('rôles des items (contrat 1.0.6)', () {
    test('rôle de l’emplacement ajouté ; omis s’il est inconnu', () {
      final it = {
        'slotId': 'j2-dips',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 8,
        'loadKg': 20,
      };
      expect(koachItemVolume(it, {'j2-dips': 'main'}), {
        'slotId': 'j2-dips',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 8,
        'targetFlames': null,
        'secondsLow': null,
        'secondsHigh': null,
        'role': 'main',
      });
      expect(koachItemVolume(it).containsKey('role'), isFalse);
      expect(koachItemVolume(it, {'autre': 'main'}).containsKey('role'), false);
    });
  });

  // KB4 (C17.40) : garde de la séance pour tous les rôles (le retrait d'un
  // accessoire par le retour gradué de 1.0.6 est retiré) :
  // test/kb4_koach107_test.dart.

  group('ordre des raisons', () {
    test('affichage dans l’ordre du contrat, quel que soit l’ordre du '
        'moteur', () {
      final a = [
        _r('koach.retour_gradue', 'x'),
        _r('koach.douleur_retrait', 'y'),
        {'code': 'inconnu'},
        _r('koach.surmenage', 'x'),
      ];
      final t1 = [for (final r in koachTrierRaisons(a)) r['code']];
      final t2 = [
        for (final r in koachTrierRaisons(a.reversed.toList())) r['code'],
      ];
      expect(t1, [
        'koach.douleur_retrait',
        'koach.surmenage',
        'koach.retour_gradue',
        'inconnu',
      ]);
      expect(t2, t1);
    });
  });

  group('programme PR2 synthétique (C17.37)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    Future<void> fresh() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
    }

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7); // lundi 19/10, S15 = S1 affichée
      await fresh();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    Future<DayPlan> open() async {
      await importPr2Nouveau(app, semaine: _semaineAvecPullOver());
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(
        app.koachEngine.fromWeek,
        15,
        reason: '${app.koachEngine.blocked}',
      );
      final base = app.program.week(15).day(1)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      return base;
    }

    // KB4 : le scénario C17.37 de Koach 1.0.6 (pull-over retiré, principaux
    // réduits) est remplacé par celui de C17.40 (programme servi à ses
    // séries écrites) : test/kb4_koach107_test.dart.

    test('raisons gardées après la première série (`plan(serie)`)', () async {
      final base = await open();
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 1)!;
      final shown = app.adaptDay(15, base, a).exercises;
      final avant = app.koachSessionReasons(15, 1, max: 9);
      final mu = shown.first;
      final ligneMu = app.koachReasonLine(15, 1, mu);
      // Première série du face pull (servi par Koach, séries classiques).
      final fp = shown.firstWhere((x) => x.catalogId == 'mu-face-pull-corde');
      final log = app.exLog(15, 1, fp);
      app.adaptPrefill(15, 1, fp, log);
      // Cible de la première série (`plan(serie)` : remplace les raisons).
      app.koachEnsureTarget(15, base, fp, 0);
      final st = app.sessionAdapt(15, 1)!.koach!;
      expect((st['cibles'] as Map).containsKey(fp.slotId), isTrue);
      final apres = app.koachSessionReasons(15, 1, max: 9);
      // Retraits et séries réduites toujours dits.
      expect(apres, containsAll(avant));
      // KB4 : la ligne de la carte du muscle-up (PR8) ne change pas après
      // `plan(serie)` d'un autre exercice.
      expect(app.koachReasonLine(15, 1, mu), ligneMu);
    });

    test('séances manquées : rôle de l’emplacement sur chaque item', () async {
      await open();
      // Aucune séance de S15 faite ; lundi suivant.
      clock = DateTime(2026, 10, 26, 7);
      await app.koachRefresh();
      final mq = app.koachEngine.manquees;
      expect(mq, isNotEmpty);
      for (final m in mq) {
        for (final it in m['items'] as List) {
          expect((it as Map).containsKey('role'), isTrue, reason: '$it');
        }
      }
    });

    test('passage depuis dev7.2.4 : prise de main de 1.0.5 gardée, séances '
        'faites, journal et programme d’origine intacts', () async {
      final base = await open();
      // Séance du lundi servie par Koach 1.0.5 en dev7.2.4 : on la marque
      // faite, puis on écrit l'instantané d'une prise de main 1.0.5.
      expect(await app.koachStart(15, base), isTrue);
      app.markSessionDone(15, 1, true);
      await app.flush();
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final engine = (doc['koachEngine'] as Map).cast<String, dynamic>();
      final snap = (engine['snap'] as Map).cast<String, dynamic>();
      snap['version_moteur'] = '1.0.5-ref.1';
      snap['version_parametres'] = '1.0.5-ref.1';
      snap['sha256_parametres'] =
          'd8a492b7debca0e4a504ed399efee0a8a6e4e003ab99f7cbb7f49c114bfbf26d';
      engine['snap'] = snap;
      doc['koachEngine'] = engine;
      final text = jsonEncode(doc);
      await app.flush();
      app.dispose();
      await fresh();
      expect(await app.importAll(text), isTrue);
      final logs = _section(app, 'logs');
      final instance = _section(app, 'programInstance');
      final origin = _section(app, 'programOrigin');
      final journal = [for (final x in app.koachEngine.journal) jsonEncode(x)];
      expect(app.programOrigin, isNotNull);
      // Lendemain : premier lancement de dev7.3.0.
      clock = DateTime(2026, 10, 20, 7);
      app.koachNoteInstall();
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.fromWeek, 15);
      expect(e.snap!.versionMoteur, '1.0.5-ref.1');
      expect(app.koachLive, isNotNull);
      expect(app.koachLive!.params['version'], ko.koachParametresVersion);
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      // Journal de 1.0.5 gardé tel quel (rattrapage ajouté après).
      expect(e.journal.length, greaterThanOrEqualTo(journal.length));
      for (var i = 0; i < journal.length; i++) {
        expect(jsonEncode(e.journal[i]), journal[i], reason: 'événement $i');
      }
      expect(app.logs[app.sessionKey(15, 1)]!.done, isTrue);
      // Mardi : séance servie par 1.0.6 (prise de main de 1.0.5 gardée).
      final j2 = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j2), isTrue);
      expect(app.koachOpen(15, 2), isTrue);
      expect(_section(app, 'programOrigin'), origin);
      expect(app.logs[app.sessionKey(15, 1)]!.done, isTrue);
    });
  });

  group('programme créé (kalis_plan)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 5, 9);
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      KoachCalcul.isolat = false;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 5, 9); // lundi
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    test('rôles de l’emplacement dans reste_semaine', () async {
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
      clock = DateTime(monday.year, monday.month, monday.day, 7);
      debugKoachBasculeAutorisee = true;
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNotNull);
      final d = app.program
          .week(w0)
          .days
          .firstWhere((x) => x.exercises.isNotEmpty);
      expect(app.adaptOpen(w0, d)?.koach?['state'], 'preview');
      expect(await app.koachStart(w0, d), isTrue);
      final reste = _contexte(app)['reste_semaine'] as List;
      expect(reste, isNotEmpty);
      final roles = <Object?>{};
      for (final s in reste) {
        for (final it in s as List) {
          expect((it as Map).containsKey('role'), isTrue, reason: '$it');
          roles.add(it['role']);
        }
      }
      expect(roles, contains('main'));
    });
  });
}
